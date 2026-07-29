import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';

/// Auth flow using Firebase's native email/password provider.
///
/// Why this replaces phone OTP entirely:
/// - `sendEmailVerification()` and `sendPasswordResetEmail()` are built-in,
///   free, and do NOT require reCAPTCHA (that's only a phone-auth thing).
/// - Firebase Auth stores and checks the password itself, so there's no more
///   need for a custom `passwordHash` field in Firestore, no custom tokens,
///   and no Cloud Functions just to authenticate someone.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ─── Auth state ────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  /// True once the user has clicked the verification link in their email.
  /// Call [reloadUser] first if you need the freshest value.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ─── Signup ─────────────────────────────────────────────────────────────────

  /// Creates the account, sends the verification email, and creates the
  /// Firestore user document. No OTP screen needed — the user just clicks
  /// the link in their inbox.
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthRepo.signUp] Creating account for $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Failed to create user account.', code: 'uid-missing');
      }

      await user.updateDisplayName(name);

      debugPrint('[AuthRepo.signUp] Sending verification email...');
      await user.sendEmailVerification();

      await _firestore.doc(FirestorePaths.userDoc(user.uid)).set({
        'name': name,
        'email': email,
        'paystackCustomerCode': null,
        'paystackAuthorizationCode': null,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
      });

      debugPrint('[AuthRepo.signUp] Account created for uid=${user.uid}, verification email sent.');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo.signUp] FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthException(_friendlyFirebaseError(e), code: e.code);
    } catch (e, stack) {
      debugPrint('[AuthRepo.signUp] Unexpected error: $e\n$stack');
      throw AuthException('Failed to sign up: $e');
    }
  }

  /// Re-sends the verification email to the currently signed-in (but
  /// unverified) user. Firebase rate-limits this itself if spammed.
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException('No signed-in user to verify.', code: 'no-current-user');
      }
      await user.sendEmailVerification();
      debugPrint('[AuthRepo.resendVerificationEmail] Sent to ${user.email}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyFirebaseError(e), code: e.code);
    }
  }

  /// Reloads the user from Firebase and returns whether their email is
  /// now verified. Call this when the user taps "I've verified my email".
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    final verified = refreshedUser?.emailVerified ?? false;

    if (verified) {
      await _firestore.doc(FirestorePaths.userDoc(refreshedUser!.uid)).update({
        'isVerified': true,
      });
      debugPrint('[AuthRepo.checkEmailVerified] uid=${refreshedUser.uid} is now verified.');
    }

    return verified;
  }

  // ─── Login ──────────────────────────────────────────────────────────────────

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthRepo.signIn] Signing in $email');
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo.signIn] FirebaseAuthException: ${e.code}');
      throw AuthException(_friendlyFirebaseError(e), code: e.code);
    } catch (e, stack) {
      debugPrint('[AuthRepo.signIn] Unexpected error: $e\n$stack');
      throw AuthException('Login error: $e');
    }
  }

  // ─── Password Reset ─────────────────────────────────────────────────────────

  /// Firebase sends its own reset email and handles the whole flow — no
  /// custom OTP screen, no reCAPTCHA.
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('[AuthRepo.sendPasswordReset] Reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo.sendPasswordReset] FirebaseAuthException: ${e.code}');
      throw AuthException(_friendlyFirebaseError(e), code: e.code);
    }
  }

  // ─── Sign out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[AuthRepo.signOut] Signed out successfully.');
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign out failed.', code: e.code);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  /// Converts Firebase Auth error codes into user-friendly messages.
  String _friendlyFirebaseError(FirebaseAuthException e) {
    debugPrint('[AuthRepo] Firebase error code="${e.code}" message="${e.message}"');
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Your password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}