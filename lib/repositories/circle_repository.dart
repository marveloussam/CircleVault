import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/firestore_paths.dart';
import '../core/enums/circle_status.dart';
import '../core/enums/member_status.dart';
import '../core/errors/app_exception.dart';
import '../models/circle_model.dart';
import '../models/member_model.dart';
import '../models/rotation_slot_model.dart';

class CircleRepository {
  CircleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  // ─── Create circle ────────────────────────────────────────────────────────────

  /// Creates a new circle document and adds the admin as the first member.
  /// Returns the created [CircleModel].
  Future<CircleModel> createCircle({
    required String adminUid,
    required String name,
    required int amountKobo,
    required String frequency,
    required int totalMembers,
  }) async {
    try {
      final circleId = _uuid.v4();
      final now = DateTime.now();

      final circle = CircleModel(
        id: circleId,
        name: name,
        adminUid: adminUid,
        contributionAmount: amountKobo,
        currency: 'NGN',
        totalMembers: totalMembers,
        currentRound: 1,
        status: CircleStatus.pending,
        frequency: frequency,
        nextContributionDate: now,
        createdAt: now,
        memberUids: [adminUid],
      );

      final batch = _firestore.batch();

      // Write circle doc
      final circleRef = _firestore.doc(FirestorePaths.circleDoc(circleId));
      batch.set(circleRef, circle.toMap());

      // Write admin as first member
      final memberRef = _firestore.doc(FirestorePaths.memberDoc(circleId, adminUid));
      final adminMember = MemberModel(
        uid: adminUid,
        circleId: circleId,
        rotationPosition: 1,
        hasReceivedPayout: false,
        status: MemberStatus.active,
        totalContributed: 0,
        joinedAt: now,
      );
      batch.set(memberRef, adminMember.toMap());

      // Create rotation slot for round 1
      final slotRef = _firestore.doc(
        FirestorePaths.rotationSlotDoc(circleId, 1),
      );
      final slot = RotationSlotModel(
        circleId: circleId,
        roundNumber: 1,
        recipientUid: adminUid,
        disbursed: false,
      );
      batch.set(slotRef, slot.toMap());

      await batch.commit();
      return circle;
    } on FirebaseException catch (e) {
      throw CircleException('Failed to create circle: ${e.message}', code: e.code);
    } catch (e) {
      throw CircleException('Unexpected error creating circle: $e');
    }
  }

// ─── Add member ───────────────────────────────────────────────────────────────

  /// Adds a new member to [circleId] and creates their rotation slot.
  /// Position is computed server-side inside a transaction to prevent
  /// race conditions when multiple members are added concurrently.
  /// If the circle is already active, the member is added as 'active'
  /// directly (skipping 'invited') so they're picked up by processContributions.
  Future<void> addMember({
    required String circleId,
    required String uid,
  }) async {
    try {
      final circleRef = _firestore.doc(FirestorePaths.circleDoc(circleId));

      await _firestore.runTransaction((transaction) async {
        final circleSnap = await transaction.get(circleRef);
        if (!circleSnap.exists) {
          throw const CircleException('Circle not found.', code: 'not-found');
        }
        final circle = CircleModel.fromMap(circleSnap.data()!, circleSnap.id);

        if (circle.isFull) {
          throw const CircleException(
            'This circle is already full.',
            code: 'circle-full',
          );
        }
        if (circle.memberUids.contains(uid)) {
          throw const CircleException(
            'User is already a member of this circle.',
            code: 'already-member',
          );
        }

        final position = circle.memberUids.length + 1;
        final now = DateTime.now();
        final isCircleActive = circle.status == CircleStatus.active;

        final memberRef = _firestore.doc(FirestorePaths.memberDoc(circleId, uid));
        final member = MemberModel(
          uid: uid,
          circleId: circleId,
          rotationPosition: position,
          hasReceivedPayout: false,
          status: isCircleActive ? MemberStatus.active : MemberStatus.invited,
          totalContributed: 0,
          joinedAt: now,
        );
        transaction.set(memberRef, member.toMap());

        final slotRef = _firestore.doc(
          FirestorePaths.rotationSlotDoc(circleId, position),
        );
        final slot = RotationSlotModel(
          circleId: circleId,
          roundNumber: position,
          recipientUid: uid,
          disbursed: false,
        );
        transaction.set(slotRef, slot.toMap());

        transaction.update(circleRef, {
          'memberUids': FieldValue.arrayUnion([uid]),
        });
      });
    } on CircleException {
      rethrow;
    } on FirebaseException catch (e) {
      throw CircleException('Failed to add member: ${e.message}', code: e.code);
    } catch (e) {
      throw CircleException('Unexpected error adding member: $e');
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
      await _firestore.doc(FirestorePaths.circleDoc(circleId)).update({
        'status': status.toValue(),
      });
    } on FirebaseException catch (e) {
      throw CircleException('Failed to update circle status: ${e.message}', code: e.code);
    } catch (e) {
      throw CircleException('Unexpected error updating circle status: $e');
    }
  }

  /// Activates the circle and sets the first contribution date to now.
  Future<void> startCircle(String circleId) async {
    try {
      await _firestore.doc(FirestorePaths.circleDoc(circleId)).update({
        'status': CircleStatus.active.toValue(),
        'nextContributionDate': Timestamp.fromDate(DateTime.now()),
      });

      // Mark all invited members as active
      final membersSnap = await _firestore
          .collection(FirestorePaths.membersCollection(circleId))
          .get();
      final batch = _firestore.batch();
      for (final doc in membersSnap.docs) {
        batch.update(doc.reference, {'status': MemberStatus.active.toValue()});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw CircleException('Failed to start circle: ${e.message}', code: e.code);
    } catch (e) {
      throw CircleException('Unexpected error starting circle: $e');
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
