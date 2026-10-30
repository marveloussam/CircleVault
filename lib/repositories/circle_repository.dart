import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/firestore_paths.dart';
import '../core/enums/circle_status.dart';
import '../core/enums/member_status.dart';
import '../core/errors/app_exception.dart';
import '../models/circle_model.dart';
import '../models/member_model.dart';
import '../models/rotation_slot_model.dart';

class CircleRepository {
  CircleRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final _uuid = const Uuid();

  Future<CircleModel> createCircle({
    required String adminUid,
    required String name,
    required int amountKobo,
    required String frequency,
    required int totalMembers,
  }) async {
    try {
      final result = await _functions.httpsCallable('createCircle').call({
        'name': name.trim(),
        'amountKobo': amountKobo,
        'frequency': frequency,
        'totalMembers': totalMembers,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final circleId = data['circleId'] as String;
      final circleAdminUid = data['adminUid'] as String? ?? adminUid;
      final now = DateTime.now();
      return CircleModel(
        id: circleId, name: name.trim(), adminUid: circleAdminUid,
        contributionAmount: amountKobo, currency: 'NGN',
        totalMembers: totalMembers, currentRound: 1,
        status: CircleStatus.pending, frequency: frequency,
        nextContributionDate: now, createdAt: now,
        memberUids: [circleAdminUid],
      );
    } catch (e) {
      throw CircleException('Failed to create circle: $e');
    }
  }

  Future<void> addMember({required String circleId, required String uid}) async {
    try {
      await _functions.httpsCallable('addCircleMember').call({
        'circleId': circleId, 'uid': uid,
      });
    } catch (e) {
      throw CircleException('Failed to add member: $e');
    }
  }

  // ─── Streams ──────────────────────────────────────────────────────────────────

  /// Live stream of all circles the user belongs to.
  Stream<List<CircleModel>> userCirclesStream(String uid) {
    return _firestore
        .collection(FirestorePaths.circlesCollection())
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CircleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Live stream of a single circle document.
  Stream<CircleModel> circleStream(String circleId) {
    return _firestore
        .doc(FirestorePaths.circleDoc(circleId))
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        throw CircleException('Circle not found.', code: 'not-found');
      }
      return CircleModel.fromMap(snap.data()!, snap.id);
    });
  }

  /// Live stream of all members in a circle.
  Stream<List<MemberModel>> membersStream(String circleId) {
    return _firestore
        .collection(FirestorePaths.membersCollection(circleId))
        .orderBy('rotationPosition')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Live stream of all rotation slots for a circle.
  Stream<List<RotationSlotModel>> rotationSlotsStream(String circleId) {
    return _firestore
        .collection(FirestorePaths.rotationSlotsCollection(circleId))
        .orderBy('roundNumber')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => RotationSlotModel.fromMap(doc.data())).toList());
  }

  // ─── Status updates ───────────────────────────────────────────────────────────

  Future<void> updateCircleStatus(String circleId, CircleStatus status) async {
    try {
      await _functions.httpsCallable('updateCircleStatus').call({
        'circleId': circleId, 'status': status.toValue(),
      });
    } catch (e) {
      throw CircleException('Failed to update circle status: $e');
    }
  }

  Future<void> startCircle(String circleId) async {
    try {
      await _functions.httpsCallable('startCircle').call({'circleId': circleId});
    } catch (e) {
      throw CircleException('Failed to start circle: $e');
    }
  }

  // ─── Fetch once ───────────────────────────────────────────────────────────────

  Future<CircleModel> getCircle(String circleId) async {
    try {
      final snap = await _firestore.doc(FirestorePaths.circleDoc(circleId)).get();
      if (!snap.exists || snap.data() == null) {
        throw const CircleException('Circle not found.', code: 'not-found');
      }
      return CircleModel.fromMap(snap.data()!, snap.id);
    } on CircleException {
      rethrow;
    } on FirebaseException catch (e) {
      throw CircleException('Failed to fetch circle: ${e.message}', code: e.code);
    } catch (e) {
      throw CircleException('Unexpected error fetching circle: $e');
    }
  }

  Future<MemberModel?> getMember(String circleId, String uid) async {
    try {
      final snap =
          await _firestore.doc(FirestorePaths.memberDoc(circleId, uid)).get();
      if (!snap.exists || snap.data() == null) return null;
      return MemberModel.fromMap(snap.data()!, snap.id);
    } on FirebaseException catch (e) {
      throw CircleException('Failed to fetch member: ${e.message}', code: e.code);
    } catch (e) {
      throw CircleException('Unexpected error fetching member: $e');
    }
  }
}

