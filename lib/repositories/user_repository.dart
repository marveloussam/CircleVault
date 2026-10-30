'import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<UserModel> getUser(String uid) async {
    try {
      final snap = await _firestore.doc(FirestorePaths.userDoc(uid)).get();
      if (!snap.exists || snap.data() == null) {
        throw AuthException('User not found.', code: 'not-found');
      }
      return UserModel.fromMap(snap.data()!, snap.id);
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AuthException('Failed to fetch user: ' + (e.message ?? ''), code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error fetching user: ' + e.toString());
    }
  }

  Future<UserModel?> getUserByEmail(String email, {required String circleId}) async {
    try {
      final result = await _functions.httpsCallable('lookupUserByEmail').call({
        'email': email.trim().toLowerCase(),
        'circleId': circleId,
      });
      final data = result.data;
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data as Map);
      return UserModel.fromMap(map, map['uid'] as String);
    } catch (e) {
      throw AuthException('Failed to look up user by email: ' + e.toString());
    }
  }

  @Deprecated('Use getUserByEmail with an authorized circle')
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    debugPrint('[UserRepository] Phone lookup is not available.');
    return null;
  }

  Future<UserModel?> findUser({String? email, String? phone, String? circleId}) async {
    if (email != null && email.isNotEmpty && circleId != null) {
      final user = await getUserByEmail(email, circleId: circleId);
      if (user != null) return user;
    }
    return null;
  }

  Stream<UserModel> userStream(String uid) {
    return _firestore.doc(FirestorePaths.userDoc(uid)).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        throw AuthException('User not found.', code: 'not-found');
      }
      return UserModel.fromMap(snap.data()!, snap.id);
    });
  }

  Future<void> updateEmail(String uid, String email) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).update({
        'email': email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException('Failed to update email: ' + (e.message ?? ''), code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating email: ' + e.toString());
    }
  }

  Future<void> updateName(String uid, String name) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).update({
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException('Failed to update name: ' + (e.message ?? ''), code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating name: ' + e.toString());
    }
  }

  Future<void> updateVerificationStatus(String uid, bool isVerified) async {
    try {
      if (!isVerified) return;
      await _functions.httpsCallable('syncEmailVerification').call();
    } catch (e) {
      throw AuthException('Failed to update verification status: ' + e.toString());
    }
  }

  Future<bool> userExistsByEmail(String email) async {
    debugPrint('[UserRepository] Use Firebase Auth for email uniqueness checks.');
    return false;
  }

  Future<bool> userExistsByPhone(String phone) async => false;

  Future<void> updateUserFields(String uid, {String? name, String? email}) async {
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (name != null) updates['name'] = name.trim();
    if (email != null) updates['email'] = email.trim().toLowerCase();
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).update(updates);
    } on FirebaseException catch (e) {
      throw AuthException('Failed to update user: ' + (e.message ?? ''), code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating user: ' + e.toString());
    }
  }
}

