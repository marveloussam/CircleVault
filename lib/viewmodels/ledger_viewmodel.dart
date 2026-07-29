import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/errors/app_exception.dart';
import '../core/enums/transaction_type.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'auth_viewmodel.dart';

class LedgerViewModel extends ChangeNotifier {
  LedgerViewModel({required TransactionRepository transactionRepository})
      : _repo = transactionRepository;

  final TransactionRepository _repo;

  // ─── State ───────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  String? _activeCircleId;
  String? get activeCircleId => _activeCircleId;

  StreamSubscription? _subscription;

  // ─── Private helpers ─────────────────────────────────────────────────────────

  void _setState(ViewState s) {
    _state = s;
    notifyListeners(); // ✅ Use ChangeNotifier's built-in method
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _setState(ViewState.error);
  }

  // ─── Watch transactions for a circle ─────────────────────────────────────────

  void watchTransactions(String circleId) {
    if (_activeCircleId == circleId && _subscription != null) return;

    _subscription?.cancel();
    _activeCircleId = circleId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      _setState(ViewState.loading);
    });

    _subscription = _repo.transactionsStream(circleId).listen(
          (txList) {
        _transactions = txList;
        _setState(ViewState.success);
      },
      onError: (e) {
        final msg =
        e is AppException ? e.message : 'Failed to load transactions.';
        _setError(msg);
      },
    );
  }

  // ─── Derived / filtered views ────────────────────────────────────────────────

  List<TransactionModel> get contributions => _transactions
      .where((t) => t.type == TransactionType.contribution)
      .toList();

  List<TransactionModel> get payouts =>
      _transactions.where((t) => t.type == TransactionType.payout).toList();

  int get totalContributedKobo =>
      contributions.fold(0, (s, t) => s + t.amountKobo);

  int get totalPaidOutKobo =>
      payouts.fold(0, (s, t) => s + t.amountKobo);

  List<TransactionModel> transactionsForMember(String uid) =>
      _transactions.where((t) => t.memberUid == uid).toList();

  List<TransactionModel> transactionsForRound(int round) =>
      _transactions.where((t) => t.roundNumber == round).toList();

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose(); // ✅ Must call super — ChangeNotifier.dispose() clears listeners
  }
}