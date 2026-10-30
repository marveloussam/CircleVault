import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/currency_formatter.dart';
import '../models/ai_tip_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class AiAdvisoryRepository {
  AiAdvisoryRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final _uuid = const Uuid();

  // ─── Generate a personalised tip ─────────────────────────────────────────

  /// [pendingContributions] — number of rounds where the user has not yet
  /// paid their contribution (due but unpaid). Pass 0 if unknown.
  Future<AiTipModel> generateTip({
    required UserModel user,
    required List<TransactionModel> recentTransactions,
    int circleCount = 0,
    int pendingContributions = 0,
  }) async {
    try {
      final userContext = _buildContext(
        user,
        recentTransactions,
        circleCount,
        pendingContributions,
      );
      debugPrint('[AiAdvisoryRepository] Prompt context: $userContext');

      final result = await _functions.httpsCallable('generateFinancialTip').call({'context': userContext});
      final tipText = (Map<String, dynamic>.from(result.data as Map)['tipText'] as String? ?? '').trim();
      if (tipText.isEmpty) throw const AiAdvisoryException('The advisory service returned no tip.', code: 'empty-tip');
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
