import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/ai_tip_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../repositories/ai_advisory_repository.dart';
import '../repositories/transaction_repository.dart';
import 'auth_viewmodel.dart'; // ViewState enum

class AiAdvisoryViewModel extends ChangeNotifier {
  AiAdvisoryViewModel({
    required AiAdvisoryRepository aiRepository,
    required TransactionRepository transactionRepository,
  })  : _aiRepo = aiRepository,
        _txRepo = transactionRepository;

  final AiAdvisoryRepository _aiRepo;
  final TransactionRepository _txRepo;

  // ─── State ────────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  AiTipModel? _currentTip;
  AiTipModel? get currentTip => _currentTip;

  List<AiTipModel> _tipHistory = [];
  List<AiTipModel> get tipHistory => List.unmodifiable(_tipHistory);

  StreamSubscription? _historySub;

  // ─── Internal helpers ─────────────────────────────────────────────────────────

  void _setState(ViewState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    debugPrint('[AiAdvisoryViewModel] ❌ Error: $msg');
    _errorMessage = msg;
    _setState(ViewState.error);
  }

  void clearError() {
    _errorMessage = null;
    _setState(ViewState.idle);
  }

  // ─── Fetch new personalised tip ───────────────────────────────────────────────

  /// IMPORTANT: Never call this directly from initState or didChangeDependencies.
  /// Always wrap the call in WidgetsBinding.instance.addPostFrameCallback(() {...})
  /// to avoid the "setState during build" assertion.
  Future<void> fetchNewTip({
    required UserModel user,
    int circleCount = 0,
  }) async {
    debugPrint('[AiAdvisoryViewModel] fetchNewTip() → '
        'uid=${user.uid}, circleCount=$circleCount');

    _setState(ViewState.loading);
    _errorMessage = null;

    List<TransactionModel> recentTx = [];
    try {
      recentTx = await _txRepo.recentUserTransactions(user.uid, limit: 20);
      debugPrint('[AiAdvisoryViewModel] Fetched ${recentTx.length} '
          'recent transactions for tip context.');
    } catch (e) {
      debugPrint('[AiAdvisoryViewModel] ⚠️ Transaction fetch failed '
          '(non-fatal, continuing with empty context): $e');
    }

    try {
      final tip = await _aiRepo.generateTip(
        user: user,
        recentTransactions: recentTx,
        circleCount: circleCount,
      );
      debugPrint('[AiAdvisoryViewModel] ✅ Tip generated: '
          'id=${tip.id}, category=${tip.category}');
      _currentTip = tip;
      _setState(ViewState.success);
    } on AiAdvisoryException catch (e) {
      _setError(e.message);
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Could not generate tip. Please try again. ($e)');
    }
  }

  // ─── Load tip history (real-time stream) ──────────────────────────────────────

  void loadHistory(String uid) {
    debugPrint('[AiAdvisoryViewModel] loadHistory() → uid=$uid');
    _historySub?.cancel();
    _historySub = _aiRepo.tipsStream(uid).listen(
          (tips) {
        debugPrint('[AiAdvisoryViewModel] History stream: '
            '${tips.length} tip(s) received.');
        _tipHistory = tips;
        if (_currentTip == null && tips.isNotEmpty) {
          _currentTip = tips.first;
          debugPrint('[AiAdvisoryViewModel] Restored currentTip '
              'from history: id=${_currentTip!.id}');
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[AiAdvisoryViewModel] ⚠️ History stream error '
            '(non-fatal): $e');
      },
    );
  }

  // ─── Dismiss a tip ────────────────────────────────────────────────────────────

  Future<void> dismissTip(String tipId) async {
    debugPrint('[AiAdvisoryViewModel] dismissTip() → id=$tipId');
    try {
      await _aiRepo.dismissTip(tipId);
      if (_currentTip?.id == tipId) {
        _currentTip = _tipHistory
            .where((t) => t.id != tipId && !t.wasDismissed)
            .firstOrNull;
        debugPrint('[AiAdvisoryViewModel] currentTip after dismiss: '
            '${_currentTip?.id ?? 'none'}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AiAdvisoryViewModel] ⚠️ dismissTip failed: $e');
    }
  }

  // ─── Category helpers ─────────────────────────────────────────────────────────

  static String categoryEmoji(String category) {
    switch (category) {
      case 'savings':    return '💰';
      case 'debt':       return '📉';
      case 'investment': return '📈';
      default:           return '💡';
    }
  }

  static String categoryLabel(String category) {
    switch (category) {
      case 'savings':    return 'Savings Tip';
      case 'debt':       return 'Debt Management';
      case 'investment': return 'Investment Advice';
      default:           return 'Financial Tip';
    }
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    debugPrint('[AiAdvisoryViewModel] dispose()');
    _historySub?.cancel();
    _historySub = null;
    super.dispose();
  }
}