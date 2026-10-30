import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/enums/circle_status.dart';
import '../core/utils/currency_formatter.dart';
import '../models/circle_model.dart';
import '../models/member_model.dart';
import '../models/rotation_slot_model.dart';
import '../models/user_model.dart';
import '../repositories/circle_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_viewmodel.dart'; // ViewState enum

class CircleViewModel extends ChangeNotifier {
  CircleViewModel({
    required CircleRepository circleRepository,
    required UserRepository userRepository,
  })  : _repo = circleRepository,
        _userRepo = userRepository;

  final CircleRepository _repo;
  final UserRepository _userRepo;

  // ─── State ────────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;

  CircleModel? _currentCircle;
  CircleModel? get currentCircle => _currentCircle;

  List<MemberModel> _members = [];
  List<MemberModel> get members => List.unmodifiable(_members);

  List<RotationSlotModel> _rotationSlots = [];
  List<RotationSlotModel> get rotationSlots =>
      List.unmodifiable(_rotationSlots);

  String? _createdCircleId;
  String? get createdCircleId => _createdCircleId;

  /// Set during [addMemberByEmail] — the resolved user before confirmation.
  UserModel? _resolvedUser;
  UserModel? get resolvedUser => _resolvedUser;

  final List<StreamSubscription> _subscriptions = [];

  // ─── Internal helpers ─────────────────────────────────────────────────────────

  void _setState(ViewState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    debugPrint('[CircleViewModel] ❌ $msg');
    _errorMessage = msg;
    _setState(ViewState.error);
  }

  void clearError() {
    _errorMessage = null;
    _setState(ViewState.idle);
  }

  // ─── Create circle ────────────────────────────────────────────────────────────

  Future<bool> createCircle({
    required String adminUid,
    required String name,
    required String amountNairaString,
    required String frequency,
    required String totalMembersString,
  }) async {
    debugPrint('[CircleViewModel] createCircle() → name=$name, '
        'amount=$amountNairaString, freq=$frequency, '
        'members=$totalMembersString');

    _setState(ViewState.loading);
    _errorMessage = null;
    _createdCircleId = null;

    try {
      final amountKobo =
      CurrencyFormatter.nairaStringToKobo(amountNairaString);
      final totalMembers = int.parse(totalMembersString.trim());

      final circle = await _repo.createCircle(
        adminUid: adminUid,
        name: name.trim(),
        amountKobo: amountKobo,
        frequency: frequency,
        totalMembers: totalMembers,
      );

      _createdCircleId = circle.id;
      _currentCircle = circle;
      debugPrint('[CircleViewModel] ✅ Circle created: id=${circle.id}');
      _setState(ViewState.success);
      return true;
    } on CircleException catch (e) {
      _setError(e.message);
      return false;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to create circle. Please try again.');
      return false;
    }
  }

  // ─── Add member by UID ────────────────────────────────────────────────────────

  Future<bool> addMember({
    required String circleId,
    required String uid,
  }) async {
    debugPrint('[CircleViewModel] addMember() → circleId=$circleId, uid=$uid');
    _setState(ViewState.loading);
    _errorMessage = null;

    try {
      await _repo.addMember(circleId: circleId, uid: uid);
      debugPrint('[CircleViewModel] ✅ Member added: uid=$uid');
      _setState(ViewState.success);
      return true;
    } on CircleException catch (e) {
      _setError(e.message);
      return false;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to add member.');
      return false;
    }
  }

  // ─── Look up user by email ────────────────────────────────────────────────────

  /// Resolves an email address to a [UserModel] without adding them yet.
  /// The UI can show a confirmation card before calling [confirmAddResolvedMember].
  ///
  /// Returns the [UserModel] on success, null if not found.
  Future<UserModel?> lookupUserByEmail(String email, {required String circleId}) async {
    final trimmedEmail = email.trim().toLowerCase();
    debugPrint('[CircleViewModel] lookupUserByEmail() → email=$trimmedEmail');

    _setState(ViewState.loading);
    _errorMessage = null;
    _resolvedUser = null;

    try {
      final user = await _userRepo.getUserByEmail(trimmedEmail, circleId: circleId);
      if (user == null) {
        _setError('No CircleVault account found with that email.');
        return null;
      }
      _resolvedUser = user;
      _setState(ViewState.success);
      return user;
    } on AppException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError('Email lookup failed. Please try again.');
      return null;
    }
  }

  /// Adds [_resolvedUser] to the circle after the user has confirmed.
  /// Call this only after a successful [lookupUserByEmail].
  Future<bool> confirmAddResolvedMember(String circleId) async {
    final user = _resolvedUser;
    if (user == null) {
      _setError('No user resolved. Run lookupUserByEmail first.');
      return false;
    }

    // Guard: already a member?
    if (_currentCircle?.memberUids.contains(user.uid) == true) {
      _setError('${user.name} is already in this circle.');
      return false;
    }

    final ok = await addMember(circleId: circleId, uid: user.uid);
    if (ok) _resolvedUser = null; // clear after successful add
    return ok;
  }

  /// Clears a previously resolved user (e.g. user tapped Cancel on confirm).
  void clearResolvedUser() {
    _resolvedUser = null;
    _setState(ViewState.idle);
  }

  // ─── Start circle ─────────────────────────────────────────────────────────────

  Future<bool> startCircle(String circleId) async {
    debugPrint('[CircleViewModel] startCircle() → id=$circleId');
    _setState(ViewState.loading);
    _errorMessage = null;
    try {
      await _repo.startCircle(circleId);
      debugPrint('[CircleViewModel] ✅ Circle started');
      _setState(ViewState.success);
      return true;
    } on CircleException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to start circle.');
      return false;
    }
  }

  // ─── Watch circle + members in real time ─────────────────────────────────────

  void watchCircle(String circleId) {
    _cancelSubscriptions();
    debugPrint('[CircleViewModel] watchCircle() → id=$circleId');

    final circleSub = _repo.circleStream(circleId).listen(
          (circle) {
        _currentCircle = circle;
        notifyListeners();
      },
      onError: (e) {
        final msg =
        e is AppException ? e.message : 'Failed to load circle.';
        _setError(msg);
      },
    );

    final membersSub = _repo.membersStream(circleId).listen(
          (members) {
        _members = members;
        notifyListeners();
      },
      onError: (e) {
        final msg =
        e is AppException ? e.message : 'Failed to load members.';
        _setError(msg);
      },
    );

    final slotsSub = _repo.rotationSlotsStream(circleId).listen(
          (slots) {
        _rotationSlots = slots;
        notifyListeners();
      },
      onError: (_) {}, // Non-critical
    );

    _subscriptions.addAll([circleSub, membersSub, slotsSub]);
  }

  // ─── Update status ────────────────────────────────────────────────────────────

  Future<bool> updateStatus(String circleId, dynamic status) async {
    debugPrint('[CircleViewModel] updateStatus() → $status');
    _setState(ViewState.loading);
    try {
      await _repo.updateCircleStatus(circleId, status);
      _setState(ViewState.success);
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update circle status.');
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  bool isAdmin(String uid) => _currentCircle?.adminUid == uid;

  MemberModel? memberFor(String uid) {
    try {
      return _members.firstWhere((m) => m.uid == uid);
    } catch (_) {
      return null;
    }
  }

  RotationSlotModel? slotForRound(int round) {
    try {
      return _rotationSlots.firstWhere((s) => s.roundNumber == round);
    } catch (_) {
      return null;
    }
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────────

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    debugPrint('[CircleViewModel] dispose()');
    _cancelSubscriptions();
    super.dispose();
  }
}