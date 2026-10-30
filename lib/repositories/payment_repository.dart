import 'package:cloud_functions/cloud_functions.dart';

class PaymentRepository {
  PaymentRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;
  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(String name, [Map<String, dynamic>? data]) async {
    final result = await _functions.httpsCallable(name).call(data ?? <String, dynamic>{});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> initializeTransaction({required String email, required int amountKobo, String? callbackUrl}) => _call('initializeCardSetup');
  Future<Map<String, dynamic>> verifyTransaction(String reference) => _call('completeCardSetup', {'reference': reference});
  Future<Map<String, dynamic>> getPaymentMethod() => _call('getPaymentMethod');
  Future<void> removePaymentMethod() async { await _call('removePaymentMethod'); }
  Future<List<Map<String, dynamic>>> getBankList() async {
    final result = await _call('getBankList');
    return List<Map<String, dynamic>>.from(result['banks'] as List);
  }
}
