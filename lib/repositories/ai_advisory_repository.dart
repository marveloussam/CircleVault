import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/currency_formatter.dart';
import '../models/ai_tip_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class AiAdvisoryRepository {
  AiAdvisoryRepository({
    http.Client? client,
    FirebaseFirestore? firestore,
  })  : _client = client ?? http.Client(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final http.Client _client;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  static const String _geminiModel = 'gemini-2.5-flash-lite';
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw const AiAdvisoryException(
        'Gemini API key not configured. Add GEMINI_API_KEY to your .env file.',
        code: 'missing-key',
      );
    }
    return key;
  }

  Uri get _endpoint => Uri.parse(
    '$_geminiBaseUrl/$_geminiModel:generateContent?key=$_apiKey',
  );

  // ─── Generate a personalised tip ─────────────────────────────────────────

  /// [pendingContributions] — number of rounds where the user has not yet
  /// paid their contribution (due but unpaid). Pass 0 if unknown.
  Future<AiTipModel> generateTip({
    required UserModel user,
    required List<TransactionModel> recentTransactions,
    int circleCount = 0,
    int pendingContributions = 0,
  }) async {
    debugPrint('[AiAdvisoryRepository] generateTip() → model=$_geminiModel, '
        'txCount=${recentTransactions.length}, circles=$circleCount, '
        'pending=$pendingContributions');

    try {
      final userContext = _buildContext(
        user,
        recentTransactions,
        circleCount,
        pendingContributions,
      );
      debugPrint('[AiAdvisoryRepository] Prompt context: $userContext');

      final response = await _client.post(
        _endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {
                'text':
                'You are a personal finance advisor for Nigerian users '
                    'participating in a ROSCA savings group called Circle Vault. '
                    'Give one concise, actionable, culturally relevant financial tip. '
                    'Be warm and encouraging. Write in plain English. Under 80 words. '
                    'Do not use bullet points or numbered lists — one flowing tip only.',
              }
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': userContext},
              ],
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 256,
            'temperature': 0.8,
            'topP': 0.95,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      debugPrint('[AiAdvisoryRepository] HTTP ${response.statusCode}');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message =
            (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
                'Gemini API error (${response.statusCode}).';
        debugPrint('[AiAdvisoryRepository] ❌ API error: $message');
        throw AiAdvisoryException(message,
            code: response.statusCode.toString());
      }

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = responseBody['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        throw const AiAdvisoryException(
          'Gemini returned no candidates.',
          code: 'no-candidates',
        );
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final finishReason = firstCandidate['finishReason'] as String?;
      debugPrint('[AiAdvisoryRepository] finishReason=$finishReason');

      if (finishReason == 'SAFETY') {
        throw const AiAdvisoryException(
          'Response blocked by Gemini safety filters.',
          code: 'safety-block',
        );
      }

      final content = firstCandidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;

      if (parts == null || parts.isEmpty) {
        throw const AiAdvisoryException(
          'Empty content in Gemini response.',
          code: 'empty-content',
        );
      }

      final tipText =
          (parts.first as Map<String, dynamic>)['text'] as String? ?? '';

      if (tipText.trim().isEmpty) {
        throw const AiAdvisoryException(
          'Gemini returned empty tip text.',
          code: 'empty-tip',
        );
      }

      debugPrint('[AiAdvisoryRepository] ✅ Tip text: $tipText');
      final category = _inferCategory(tipText);

      final tip = AiTipModel(
        id: _uuid.v4(),
        uid: user.uid,
        tipText: tipText.trim(),
        category: category,
        generatedAt: DateTime.now(),
        wasDismissed: false,
      );

      await _cacheTip(tip);
      return tip;
    } on AiAdvisoryException {
      rethrow;
    } catch (e) {
      throw AiAdvisoryException('Failed to generate AI tip: $e');
    }
  }

  // ─── Cache tip in Firestore ───────────────────────────────────────────────
  // Requires Firestore rule:
  //   allow create: if request.auth != null
  //                 && request.resource.data.uid == request.auth.uid;

  Future<void> _cacheTip(AiTipModel tip) async {
    try {
      await _firestore.doc(FirestorePaths.aiTipDoc(tip.id)).set(tip.toMap());
      debugPrint('[AiAdvisoryRepository] Tip cached: id=${tip.id}');
    } catch (e) {
      // Non-fatal — the tip is still returned to the caller even if caching fails.
      debugPrint('[AiAdvisoryRepository] ⚠️ Cache failed (non-fatal): $e');
    }
  }

  // ─── Real-time tip history stream ─────────────────────────────────────────

  Stream<List<AiTipModel>> tipsStream(String uid) {
    return _firestore
        .collection(FirestorePaths.aiTipsCollection())
        .where('uid', isEqualTo: uid)
        .where('wasDismissed', isEqualTo: false)
        .orderBy('generatedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => AiTipModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ─── Dismiss a tip ────────────────────────────────────────────────────────

  Future<void> dismissTip(String tipId) async {
    try {
      await _firestore
          .doc(FirestorePaths.aiTipDoc(tipId))
          .update({'wasDismissed': true});
    } on FirebaseException catch (e) {
      throw AiAdvisoryException(
        'Failed to dismiss tip: ${e.message}',
        code: e.code,
      );
    }
  }

  // ─── Context builder ──────────────────────────────────────────────────────

  String _buildContext(
      UserModel user,
      List<TransactionModel> transactions,
      int circleCount,
      int pendingContributions,
      ) {
    // Only count contribution-type transactions for the savings total
    final contributions =
    transactions.where((t) => t.type.toValue() == 'contribution').toList();
    final payouts =
    transactions.where((t) => t.type.toValue() == 'payout').toList();

    final totalContributedKobo =
    contributions.fold<int>(0, (sum, tx) => sum + tx.amountKobo);
    final totalContributed = CurrencyFormatter.format(totalContributedKobo);

    // Approximate tenure from oldest contribution
    final monthsActive = contributions.isNotEmpty
        ? DateTime.now()
        .difference(contributions.last.timestamp)
        .inDays ~/
        30
        : 0;

    final payoutCount = payouts.length;

    // Build a natural-language sentence about pending payments only when relevant
    final pendingClause = pendingContributions > 0
        ? 'I currently have $pendingContributions pending contribution(s) '
        'that are due but not yet paid. '
        : '';

    // Build circle membership sentence
    final circleClause = circleCount == 1
        ? 'I am currently a member of 1 savings circle on Circle Vault. '
        : circleCount > 1
        ? 'I am currently a member of $circleCount savings circles on Circle Vault. '
        : 'I have just joined Circle Vault and am not yet in any savings circle. ';

    return 'My name is ${user.name}. '
        '$circleClause'
        'I have contributed a total of $totalContributed '
        'over approximately $monthsActive month(s). '
        'I have received $payoutCount payout(s) so far. '
        '${pendingClause}'
        'Give me one personalised financial tip based on this activity.';
  }

  // ─── Category inference ───────────────────────────────────────────────────

  String _inferCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('invest') ||
        lower.contains('stock') ||
        lower.contains('asset') ||
        lower.contains('treasury') ||
        lower.contains('fund')) {
      return 'investment';
    }
    if (lower.contains('debt') ||
        lower.contains('loan') ||
        lower.contains('borrow') ||
        lower.contains('credit')) {
      return 'debt';
    }
    if (lower.contains('save') ||
        lower.contains('saving') ||
        lower.contains('emergency') ||
        lower.contains('budget')) {
      return 'savings';
    }
    return 'general';
  }
}