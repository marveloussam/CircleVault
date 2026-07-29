import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/circle_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../repositories/circle_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_viewmodel.dart';

class HomeViewModel  extends ChangeNotifier{
  HomeViewModel({
    required UserRepository userRepository,
    required CircleRepository circleRepository,
    required TransactionRepository transactionRepository,
  })  : _userRepo = userRepository,
        _circleRepo = circleRepository,
        _txRepo = transactionRepository;

  final UserRepository _userRepo;
  final CircleRepository _circleRepo;
  final TransactionRepository _txRepo;

  // ─── State ────────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  ViewState get state => _state;
  bool get hasError => _state == ViewState.error;   // ← added

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _user;
  UserModel? get user => _user;

  List<CircleModel> _circles = [];
  List<CircleModel> get circles => List.unmodifiable(_circles);

  List<TransactionModel> _recentTransactions = [];
  List<TransactionModel> get recentTransactions =>
      List.unmodifiable(_recentTransactions);

  bool get isLoading => _state == ViewState.loading;

  /// Total contributed by the user across all circles (in kobo).
  int get totalSavingsKobo =>
      _recentTransactions.fold(0, (sum, tx) => sum + tx.amountKobo);

  final List<void Function()> _listeners = [];
  final List<StreamSubscription> _subscriptions = [];

  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);

  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  void _setState(ViewState s) {
    _state = s;
    _notify();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ViewState.error);
  }

  // ─── Init — wire up all streams ───────────────────────────────────────────────

  void init(String uid) {
    _setState(ViewState.loading);

    // Stream 1: user profile
    final userSub = _userRepo.userStream(uid).listen(
      (user) {
        _user = user;
        if (_state == ViewState.loading) _setState(ViewState.success);
        _notify();
      },
      onError: (e) {
        final msg = e is AppException ? e.message : 'Failed to load profile.';
        _setError(msg);
      },
    );

    // Stream 2: user's circles
    final circlesSub = _circleRepo.userCirclesStream(uid).listen(
      (circles) {
        _circles = circles;
        _notify();
      },
      onError: (e) {
        final msg = e is AppException ? e.message : 'Failed to load circles.';
        _setError(msg);
      },
    );

    // Stream 3: recent transactions (one-time fetch, not streamed)
    _loadRecentTransactions(uid);

    _subscriptions.addAll([userSub, circlesSub]);
  }

  Future<void> _loadRecentTransactions(String uid) async {
    try {
      _recentTransactions = await _txRepo.recentUserTransactions(uid, limit: 5);
      _notify();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (_) {
      // Non-critical — home still usable without transaction history
    }
  }

  /// Pull-to-refresh: re-fetches recent transactions.
  Future<void> refresh(String uid) async {
    await _loadRecentTransactions(uid);
  }
  Future<void> updateName(String uid, String name) async {
    await _userRepo.updateName(uid,  name);
    // The userStream will automatically emit the updated UserModel
  }
  // ─── Dispose ──────────────────────────────────────────────────────────────────

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _listeners.clear();
  }
}
