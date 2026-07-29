import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ─── Fetch user by UID ────────────────────────────────────────────────────────

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
      throw AuthException('Failed to fetch user: ${e.message}', code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error fetching user: $e');
    }
  }

  // ─── Fetch user by email ──────────────────────────────────────────────────────

  /// Looks up a user document by [email].
  /// Email is case-insensitive (stored in lowercase).
  /// Returns null if no matching user is found.
  Future<UserModel?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    debugPrint('[UserRepository] getUserByEmail() → $normalizedEmail');

    try {
      final snap = await _firestore
          .collection(FirestorePaths.usersCollection())
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('[UserRepository] No user found for email: $normalizedEmail');
        return null;
      }

      final doc = snap.docs.first;
      final user = UserModel.fromMap(doc.data(), doc.id);
      debugPrint('[UserRepository] Found user: uid=${user.uid}, '
          'name=${user.name}, email=${user.email}');
      return user;
    } on FirebaseException catch (e) {
      throw AuthException(
          'Failed to look up user by email: ${e.message}',
          code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error looking up user: $e');
    }
  }

  // ─── Fetch user by phone (deprecated, kept for backward compatibility) ─────

  /// ⚠️ DEPRECATED: Use getUserByEmail instead.
  /// Looks up a user document by [phoneNumber].
  /// Returns null if no matching user is found.
  @Deprecated('Use getUserByEmail instead')
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    debugPrint('[UserRepository] getUserByPhone() → $phoneNumber (deprecated)');
    try {
      final snap = await _firestore
          .collection(FirestorePaths.usersCollection())
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('[UserRepository] No user found for phone: $phoneNumber');
        return null;
      }

      final doc = snap.docs.first;
      final user = UserModel.fromMap(doc.data(), doc.id);
      debugPrint('[UserRepository] Found user: uid=${user.uid}, '
          'name=${user.name}');
      return user;
    } on FirebaseException catch (e) {
      throw AuthException(
          'Failed to look up user by phone: ${e.message}',
          code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error looking up user: $e');
    }
  }

  // ─── Get user by email or phone (flexible lookup) ──────────────────────────

  /// Tries to find a user by email first, then by phone if provided.
  /// Useful for migration periods where users might have either.
  Future<UserModel?> findUser({
    String? email,
    String? phone,
  }) async {
    if (email != null && email.isNotEmpty) {
      final user = await getUserByEmail(email);
      if (user != null) return user;
    }

    if (phone != null && phone.isNotEmpty) {
      final user = await getUserByPhone(phone);
      if (user != null) return user;
    }

    return null;
  }

  // ─── Real-time stream ─────────────────────────────────────────────────────────

  Stream<UserModel> userStream(String uid) {
    return _firestore
        .doc(FirestorePaths.userDoc(uid))
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        throw AuthException('User not found.', code: 'not-found');
      }
      return UserModel.fromMap(snap.data()!, snap.id);
    });
  }

  // ─── Update user email (for migration or changes) ───────────────────────────

  Future<void> updateEmail(String uid, String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _firestore
          .doc(FirestorePaths.userDoc(uid))
          .update({'email': normalizedEmail});
      debugPrint('[UserRepository] Updated email for uid: $uid');
    } on FirebaseException catch (e) {
      throw AuthException('Failed to update email: ${e.message}', code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating email: $e');
    }
  }

  // ─── Update display name ──────────────────────────────────────────────────────

  Future<void> updateName(String uid, String name) async {
    try {
      await _firestore
          .doc(FirestorePaths.userDoc(uid))
          .update({'name': name.trim()});
      debugPrint('[UserRepository] Updated name for uid: $uid');
    } on FirebaseException catch (e) {
      throw AuthException('Failed to update name: ${e.message}', code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating name: $e');
    }
  }

  // ─── Update verification status ──────────────────────────────────────────────

  Future<void> updateVerificationStatus(String uid, bool isVerified) async {
    try {
      await _firestore
          .doc(FirestorePaths.userDoc(uid))
          .update({'isVerified': isVerified});
      debugPrint('[UserRepository] Updated verification for uid: $uid → $isVerified');
    } on FirebaseException catch (e) {
      throw AuthException(
          'Failed to update verification status: ${e.message}',
          code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating verification status: $e');
    }
  }

  // ─── Update Paystack auth ─────────────────────────────────────────────────────

  Future<void> updatePaystackAuth(
      String uid, {
        required String customerCode,
        required String authorizationCode,
        required String last4,
        required String bank,
        required String signature,
      }) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).set({
        'paystackCustomerCode': customerCode,
        'paystackAuthorizationCode': authorizationCode,
        'paystackCardLast4': last4,
        'paystackCardBank': bank,
        'paystackCardSignature': signature,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[UserRepository] Updated Paystack auth for uid: $uid');
    } on FirebaseException catch (e) {
      throw AuthException(
          'Failed to update payment info: ${e.message}',
          code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating payment info: $e');
    }
  }

  // ─── Get Paystack details ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getPaystackDetails(String uid) async {
    debugPrint('[UserRepository] getPaystackDetails() — uid=$uid');
    try {
      final doc = await _firestore.doc(FirestorePaths.userDoc(uid)).get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('[UserRepository] getPaystackDetails — doc not found');
        return null;
      }

      final data = doc.data()!;
      final authCode = data['paystackAuthorizationCode'] as String?;

      debugPrint('[UserRepository] getPaystackDetails — '
          'authCode=${authCode != null ? "present" : "null"}, '
          'last4=${data['paystackCardLast4']}, '
          'bank=${data['paystackCardBank']}');

      if (authCode == null || authCode.isEmpty) return null;

      return {
        'authorizationCode': authCode,
        'paystackCustomerCode': data['paystackCustomerCode'],
        'paystackCardLast4': data['paystackCardLast4'],
        'paystackCardBank': data['paystackCardBank'],
        'paystackCardSignature': data['paystackCardSignature'],
      };
    } on FirebaseException catch (e) {
      debugPrint('[UserRepository] getPaystackDetails FirebaseException: '
          '${e.code} — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[UserRepository] getPaystackDetails error: $e');
      return null;
    }
  }

  // ─── Update transfer recipient code ──────────────────────────────────────────

  Future<void> updateTransferRecipientCode(
      String uid,
      String recipientCode,
      ) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).set({
        'paystackTransferRecipientCode': recipientCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[UserRepository] Updated transfer recipient for uid: $uid');
    } on FirebaseException catch (e) {
      throw AuthException(
          'Failed to update transfer recipient: ${e.message}',
          code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating transfer recipient: $e');
    }
  }

  // ─── Remove card ─────────────────────────────────────────────────────────────

  Future<void> removeCard(String uid) async {
    try {
      await _firestore.doc(FirestorePaths.userDoc(uid)).update({
        'paystackCustomerCode': FieldValue.delete(),
        'paystackAuthorizationCode': FieldValue.delete(),
        'paystackCardLast4': FieldValue.delete(),
        'paystackCardBank': FieldValue.delete(),
        'paystackCardSignature': FieldValue.delete(),
      });
      debugPrint('[UserRepository] Removed card for uid: $uid');
    } on FirebaseException catch (e) {
      throw AuthException('Failed to remove card: ${e.message}', code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error removing card: $e');
    }
  }

  // ─── Check if user exists by email ───────────────────────────────────────────

  Future<bool> userExistsByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final snap = await _firestore
          .collection(FirestorePaths.usersCollection())
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[UserRepository] userExistsByEmail error: $e');
      return false;
    }
  }

  // ─── Check if user exists by phone ───────────────────────────────────────────

  Future<bool> userExistsByPhone(String phone) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.usersCollection())
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[UserRepository] userExistsByPhone error: $e');
      return false;
    }
  }

  // ─── Batch update multiple fields ────────────────────────────────────────────

  Future<void> updateUserFields(
      String uid, {
        String? name,
        String? email,
        bool? isVerified,
        String? paystackCustomerCode,
        String? paystackAuthorizationCode,
        String? paystackTransferRecipientCode,
        String? paystackCardLast4,
        String? paystackCardBank,
        String? paystackCardSignature,
      }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name.trim();
      if (email != null) updates['email'] = email.trim().toLowerCase();
      if (isVerified != null) updates['isVerified'] = isVerified;
      if (paystackCustomerCode != null) {
        updates['paystackCustomerCode'] = paystackCustomerCode;
      }
      if (paystackAuthorizationCode != null) {
        updates['paystackAuthorizationCode'] = paystackAuthorizationCode;
      }
      if (paystackTransferRecipientCode != null) {
        updates['paystackTransferRecipientCode'] = paystackTransferRecipientCode;
      }
      if (paystackCardLast4 != null) {
        updates['paystackCardLast4'] = paystackCardLast4;
      }
      if (paystackCardBank != null) {
        updates['paystackCardBank'] = paystackCardBank;
      }
      if (paystackCardSignature != null) {
        updates['paystackCardSignature'] = paystackCardSignature;
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      if (updates.isNotEmpty) {
        await _firestore.doc(FirestorePaths.userDoc(uid)).update(updates);
        debugPrint('[UserRepository] Updated multiple fields for uid: $uid');
      }
    } on FirebaseException catch (e) {
      throw AuthException('Failed to update user: ${e.message}', code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error updating user: $e');
    }
  }
}