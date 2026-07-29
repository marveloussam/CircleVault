import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../repositories/auth_repository.dart';

enum ViewState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
      : _repo = authRepository;

  final AuthRepository _repo;

  // ─── State ────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  void _setState(ViewState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ViewState.error);
  }

  void clearError() {
    _errorMessage = null;
    _setState(ViewState.idle);
  }

  // ─── Auth state stream ─────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _repo.authStateChanges;

  bool get isLoggedIn => _repo.isLoggedIn;

  User? get currentUser => _repo.currentUser;

  bool get isEmailVerified => _repo.isEmailVerified;

  // ─── Signup ─────────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = null;

    debugPrint('[AuthVM.signUp] Signing up with email=$email');

    try {
      await _repo.signUp(
        name: name,
        email: email,
        password: password,
      );
      debugPrint('[AuthVM.signUp] Signup successful. Verification email sent.');
      _setState(ViewState.success);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthVM.signUp] AuthException: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      debugPrint('[AuthVM.signUp] Unexpected: $e');
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ─── Email Verification ─────────────────────────────────────────────────────

  Future<bool> checkEmailVerified() async {
    _setState(ViewState.loading);
    _errorMessage = null;

    try {
      final isVerified = await _repo.checkEmailVerified();
      debugPrint('[AuthVM.checkEmailVerified] Verified: $isVerified');
      _setState(ViewState.success);
      return isVerified;
    } on AuthException catch (e) {
      debugPrint('[AuthVM.checkEmailVerified] AuthException: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      debugPrint('[AuthVM.checkEmailVerified] Unexpected: $e');
      _setError('Failed to check verification status.');
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _setState(ViewState.loading);
    _errorMessage = null;

    try {
      await _repo.resendVerificationEmail();
      debugPrint('[AuthVM.resendVerificationEmail] Resent successfully.');
      _setState(ViewState.success);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthVM.resendVerificationEmail] AuthException: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      debugPrint('[AuthVM.resendVerificationEmail] Unexpected: $e');
      _setError('Failed to resend verification email.');
      return false;
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = null;

    debugPrint('[AuthVM.signIn] Signing in with email=$email');

    try {
      await _repo.signIn(email: email, password: password);
      debugPrint('[AuthVM.signIn] Sign in successful.');
      _setState(ViewState.success);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthVM.signIn] AuthException: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      debugPrint('[AuthVM.signIn] Unexpected: $e');
      _setError('Login failed. Please check your credentials.');
      return false;
    }
  }

  // ─── Password Reset ────────────────────────────────────────────────────────

  Future<bool> sendPasswordReset({required String email}) async {
    _setState(ViewState.loading);
    _errorMessage = null;

    debugPrint('[AuthVM.sendPasswordReset] Sending reset email to $email');

    try {
      await _repo.sendPasswordReset(email: email);
      debugPrint('[AuthVM.sendPasswordReset] Reset email sent.');
      _setState(ViewState.success);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthVM.sendPasswordReset] AuthException: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      debugPrint('[AuthVM.sendPasswordReset] Unexpected: $e');
      _setError('Failed to send password reset email.');
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _setState(ViewState.loading);
    try {
      await _repo.signOut();
      debugPrint('[AuthVM.logout] Signed out.');
      _setState(ViewState.idle);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Sign out failed.');
    }
  }
}