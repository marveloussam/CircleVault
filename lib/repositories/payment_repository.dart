import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';

class PaymentRepository {
  PaymentRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _uuid = const Uuid();

  static const String _baseUrl = 'https://api.paystack.co';

  String get _secretKey {
    final key = dotenv.env['PAYSTACK_SECRET_KEY'];
    if (key == null || key.isEmpty) {
      throw const PaymentException(
        'Paystack secret key not configured.',
        code: 'missing-key',
      );
    }
    return key;
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required int amountKobo,
    String? callbackUrl,
  }) async {
    try {
      final reference =
          'cv_init_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';

      final body = {
        'email': email,
        'amount': amountKobo,
        'reference': reference,
        'channels': ['card'],
        if (callbackUrl != null) 'callback_url': callbackUrl,
      };

      print('🚀 Initializing Paystack transaction');
      print('URL: $_baseUrl/transaction/initialize');
      print('Reference: $reference');
      print('Email: $email');
      print('Amount: $amountKobo');

      final response = await _client.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('✅ Initialize Response (${response.statusCode})');
      print(response.body);

      final data = _parseResponse(response);

      final result = data['data'] as Map<String, dynamic>;

      print('🔗 Authorization URL: ${result['authorization_url']}');

      return result;
    } on PaymentException {
      rethrow;
    } catch (e) {
      print('❌ Initialize Transaction Error: $e');
      throw PaymentException('Failed to initialize transaction: $e');
    }
  }
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    try {
      print('🔍 Verifying transaction');
      print('Reference: $reference');
      print('URL: $_baseUrl/transaction/verify/$reference');

      final response = await _client.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: _headers,
      );

      print('✅ Verify Response (${response.statusCode})');
      print(response.body);

      final data = _parseResponse(response);

      final result = data['data'] as Map<String, dynamic>;

      final authorization =
      result['authorization'] as Map<String, dynamic>?;

      print('💳 Authorization Found: ${authorization != null}');
      print('♻️ Reusable: ${authorization?['reusable']}');
      print('🔑 Authorization Code: ${authorization?['authorization_code']}');

      return result;
    } on PaymentException {
      rethrow;
    } catch (e) {
      print('❌ Verify Transaction Error: $e');
      throw PaymentException('Failed to verify transaction: $e');
    }
  }
  Future<Map<String, dynamic>> chargeAuthorization({
    required String authorizationCode,
    required String email,
    required int amountKobo,
    String? reference,
  }) async {
    try {
      final ref = reference ??
          'cv_charge_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';

      final body = {
        'authorization_code': authorizationCode,
        'email': email,
        'amount': amountKobo,
        'reference': ref,
      };

      print('💳 Charging Authorization');
      print('Reference: $ref');
      print('Email: $email');
      print('Amount: $amountKobo');

      final response = await _client.post(
        Uri.parse('$_baseUrl/charge/authorization'),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('✅ Charge Response (${response.statusCode})');
      print(response.body);

      final data = _parseResponse(response);

      return data['data'] as Map<String, dynamic>;
    } on PaymentException {
      rethrow;
    } catch (e) {
      print('❌ Charge Authorization Error: $e');
      throw PaymentException('Failed to charge card: $e');
    }
  }
  // ─── Create transfer recipient ────────────────────────────────────────────────

  /// Creates a Paystack transfer recipient (bank account) for payout.
  /// [bankCode] follows Paystack's bank code list (e.g. "058" for GTBank).
  Future<Map<String, dynamic>> createTransferRecipient({
    required String accountName,
    required String accountNumber,
    required String bankCode,
    String currency = 'NGN',
  }) async {
    try {
      final body = {
        'type': 'nuban',
        'name': accountName,
        'account_number': accountNumber,
        'bank_code': bankCode,
        'currency': currency,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/transferrecipient'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final data = _parseResponse(response);
      return data['data'] as Map<String, dynamic>;
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Failed to create transfer recipient: $e');
    }
  }

  // ─── Initiate payout transfer ─────────────────────────────────────────────────

  /// Sends funds to a Paystack transfer recipient (payout disbursement).
  /// [recipientCode] comes from [createTransferRecipient] response.
  Future<Map<String, dynamic>> initiatePayout({
    required String recipientCode,
    required int amountKobo,
    required String reference,
    String? reason,
  }) async {
    try {
      final body = {
        'source': 'balance',
        'amount': amountKobo,
        'recipient': recipientCode,
        'reference': reference,
        if (reason != null) 'reason': reason,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/transfer'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final data = _parseResponse(response);
      return data['data'] as Map<String, dynamic>;
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Failed to initiate payout: $e');
    }
  }

  // ─── Verify transfer ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyTransfer(String reference) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/transfer/verify/$reference'),
        headers: _headers,
      );
      final data = _parseResponse(response);
      return data['data'] as Map<String, dynamic>;
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Failed to verify transfer: $e');
    }
  }

  // ─── Fetch bank list ──────────────────────────────────────────────────────────

  /// Returns Paystack's list of Nigerian banks with their codes.
  Future<List<Map<String, dynamic>>> getBankList() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/bank?country=nigeria&perPage=100'),
        headers: _headers,
      );
      final data = _parseResponse(response);
      return List<Map<String, dynamic>>.from(data['data'] as List);
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Failed to fetch bank list: $e');
    }
  }

  // ─── Helper ───────────────────────────────────────────────────────────────────

  /// Parses an HTTP response, throws [PaymentException] on non-2xx or API errors.
  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw PaymentException(
        'Invalid response from Paystack (status ${response.statusCode}).',
        code: 'parse-error',
      );
    }

    final status = body['status'];
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        status == true) {
      return body;
    }

    final message = body['message'] as String? ?? 'Unknown Paystack error.';
    throw PaymentException(message, code: response.statusCode.toString());
  }
}
