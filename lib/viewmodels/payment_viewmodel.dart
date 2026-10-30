import 'package:flutter/material.dart';
import '../core/errors/app_exception.dart';
import '../repositories/payment_repository.dart';
import 'auth_viewmodel.dart';

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({required PaymentRepository paymentRepository}) : _paymentRepo = paymentRepository;
  final PaymentRepository _paymentRepo;
  ViewState _state = ViewState.idle;
  ViewState get state => _state;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _cardAdded = false;
  bool get cardAdded => _cardAdded;
  bool get isLoading => _state == ViewState.loading;
  Map<String, dynamic>? _card;
  Map<String, dynamic>? get card => _card;
  bool get hasLinkedCard => _card?['hasLinkedCard'] == true;
  void _setState(ViewState s) { _state = s; notifyListeners(); }
  void _setError(String msg) { _errorMessage = msg; _setState(ViewState.error); }
  void clearError() { _errorMessage = null; _setState(ViewState.idle); }
  Future<void> loadCard(String uid) async {
    try {
      final method = await _paymentRepo.getPaymentMethod();
      _card = {
        'hasLinkedCard': method['hasLinkedCard'] == true,
        'paystackCardLast4': method['last4'] ?? '',
        'paystackCardBank': method['bank'] ?? '',
      };
      notifyListeners();
    } catch (_) {}
  }
  Future<({String authorizationUrl, String reference})?> prepareCardSetup({required String uid}) async {
    _setState(ViewState.loading); _errorMessage = null; _cardAdded = false;
    try {
      final data = await _paymentRepo.initializeTransaction(email: '', amountKobo: 5000);
      final url = data['authorizationUrl'] as String?; final reference = data['reference'] as String?;
      if (url == null || reference == null) throw const PaymentException('Invalid response from payment gateway.', code: 'init-failed');
      _setState(ViewState.idle); return (authorizationUrl: url, reference: reference);
    } catch (e) { _setError('Failed to prepare card setup. Please try again.'); return null; }
  }
  Future<bool> verifyAndSaveCard({required String uid, required String reference}) async {
    _setState(ViewState.loading); _errorMessage = null;
    try {
      final method = await _paymentRepo.verifyTransaction(reference);
      _card = {
        'hasLinkedCard': method['hasLinkedCard'] == true,
        'paystackCardLast4': method['last4'] ?? '',
        'paystackCardBank': method['bank'] ?? '',
      };
      _cardAdded = _card?['hasLinkedCard'] == true;
      _setState(ViewState.success);
      return _cardAdded;
    }
    catch (_) { _setError('Card verification failed. Please try again.'); return false; }
  }
  Future<void> removeCard(String uid) async {
    _setState(ViewState.loading);
    try { await _paymentRepo.removePaymentMethod(); _card = null; _setState(ViewState.success); }
    catch (_) { _setError('Failed to remove card.'); }
  }
}
