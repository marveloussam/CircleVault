import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/errors/app_exception.dart';
import '../repositories/payment_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_viewmodel.dart';

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    required PaymentRepository paymentRepository,
    required UserRepository userRepository,
  })  : _paymentRepo = paymentRepository,
        _userRepo = userRepository;

  final PaymentRepository _paymentRepo;
  final UserRepository _userRepo;

  // ─── State ────────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _cardAdded = false;
  bool get cardAdded => _cardAdded;

  bool get isLoading => _state == ViewState.loading;


  Map<String, dynamic>? _card;

  Map<String, dynamic>? get card => _card;

  Future<void> loadCard(String uid) async {
    try {
      _card = await _userRepo.getPaystackDetails(uid);
      notifyListeners();
    } catch (_) {}
  }

  bool get hasLinkedCard {
    return _card?['authorizationCode'] != null;
  }
  void _setState(ViewState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _setState(ViewState.error);
  }

  void clearError() {
    _errorMessage = null;
    _setState(ViewState.idle);
  }


  Future<({String authorizationUrl, String reference})?> prepareCardSetup({
    required String uid,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = null;
    _cardAdded = false;

    try {
      final email = '$uid@circlevault.app';

      final initData = await _paymentRepo.initializeTransaction(
        email: email,
        amountKobo: 5000, // NGN 50 verification charge
      );

      final authorizationUrl = initData['authorization_url'] as String?;
      final reference = initData['reference'] as String?;

      if (authorizationUrl == null || reference == null) {
        throw const PaymentException(
          'Invalid response from payment gateway.',
          code: 'init-failed',
        );
      }

      _setState(ViewState.idle);
      return (authorizationUrl: authorizationUrl, reference: reference);
    } on PaymentException catch (e) {
      _setError(e.message);
      return null;
    } on AppException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError('Failed to prepare card setup. Please try again.');
      return null;
    }
  }

  Future<bool> chargeUser({
    required String authorizationCode,
    required String email,
    required int amountKobo,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = null;
    try {
      await _paymentRepo.chargeAuthorization(
        authorizationCode: authorizationCode,
        email: email,
        amountKobo: amountKobo,
      );
      _setState(ViewState.success);
      return true;
    } on PaymentException catch (e) {
      _setError(e.message);
      return false;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to charge card. Please try again.');
      return false;
    }
  }
  // ─── Verify and save after WebView completes ──────────────────────────────────

  /// Called after the Paystack WebView redirects with a reference.
  /// Verifies the transaction and saves the authorization code to Firestore.
  Future<bool> verifyAndSaveCard({
    required String uid,
    required String reference,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = null;

    try {
      final verification = await _paymentRepo.verifyTransaction(reference);
      debugPrint(
        'VERIFY RESPONSE: ${jsonEncode(verification)}',
      );
      debugPrint(
        'AUTHORIZATION: ${jsonEncode(verification['authorization'])}',
      );
      // Check transaction status
      final txStatus = verification['status'] as String?;
      if (txStatus != 'success') {
        throw PaymentException(
          'Transaction was not successful (status: $txStatus).',
          code: 'tx-not-success',
        );
      }



      final authorization =
      verification['authorization'] as Map<String, dynamic>?;

      final customer =
      verification['customer'] as Map<String, dynamic>?;

      final authCode =
      authorization?['authorization_code'] as String?;

      final customerCode =
      customer?['customer_code'] as String?;

      final reusable =
          authorization?['reusable'] as bool? ?? false;

      final last4 =
          authorization?['last4'] as String? ?? '';

      final bank =
          authorization?['bank'] as String? ?? '';

      final signature =
          authorization?['signature'] as String? ?? '';

      if (!reusable) {
        throw const PaymentException(
          'This card cannot be used for recurring payments.',
          code: 'not-reusable',
        );
      }

      await _userRepo.updatePaystackAuth(
        uid,
        customerCode: customerCode ?? '',
        authorizationCode: authCode?? '',
        last4: last4,
        bank: bank,
        signature: signature,
      );
      _cardAdded = true;
      _setState(ViewState.success);
      return true;
    } on PaymentException catch (e) {
      _setError(e.message);
      return false;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Card verification failed. Please try again.');
      return false;
    }
  }

  Future<void> removeCard(String uid) async {
    _setState(ViewState.loading);

    try {
      await _userRepo.removeCard(uid);

      _card = null;

      _setState(ViewState.success);
    } catch (e) {
      _setError('Failed to remove card.');
    }
  }
  @override
  void dispose() {
    super.dispose();
  }
}