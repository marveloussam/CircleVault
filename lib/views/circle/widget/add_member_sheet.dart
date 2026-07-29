import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/circle_viewmodel.dart';
import '../../../widgets/common/error_snackbar.dart';

void showAddMemberSheet(
    BuildContext context, {
      required CircleViewModel vm,
      required String circleId,
    }) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: _AddMemberSheet(circleId: circleId),
    ),
  );
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.circleId});
  final String circleId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _emailCtrl = TextEditingController(); // Changed from phone
  final _uidCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Which input mode is active
  bool _useEmail = true; // Changed from _usePhone

  // The user found after an email lookup — shown as a confirm card
  UserModel? _foundUser;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLookup(CircleViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final user = await vm.lookupUserByEmail(_emailCtrl.text.trim());

    if (!mounted) return;
    if (user != null) {
      setState(() => _foundUser = user);
    } else {
      AppSnackbar.showError(
          context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  Future<void> _onConfirmAdd(CircleViewModel vm) async {
    final ok = await vm.confirmAddResolvedMember(widget.circleId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(
          context, '${_foundUser?.name ?? 'Member'} added successfully!');
    } else {
      setState(() => _foundUser = null); // reset so user can try again
      AppSnackbar.showError(
          context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  Future<void> _onAddByUid(CircleViewModel vm) async {
    final uid = _uidCtrl.text.trim();
    if (uid.isEmpty) return;
    FocusScope.of(context).unfocus();

    final ok = await vm.addMember(circleId: widget.circleId, uid: uid);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Member added successfully!');
    } else {
      AppSnackbar.showError(
          context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<CircleViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Title ────────────────────────────────────────────
                const Text(
                  'Add Member',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Search by email address or enter a user ID directly.',
                  style: TextStyle(color: Color(0xFF888899), fontSize: 13),
                ),

                const SizedBox(height: 20),

                // ── Toggle: Email / UID ───────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _TabChip(
                        label: '✉️  Email Address',
                        isActive: _useEmail,
                        onTap: () {
                          setState(() {
                            _useEmail = true;
                            _foundUser = null;
                            vm.clearResolvedUser();
                          });
                        },
                      ),
                      _TabChip(
                        label: '🔑  User ID',
                        isActive: !_useEmail,
                        onTap: () {
                          setState(() {
                            _useEmail = false;
                            _foundUser = null;
                            vm.clearResolvedUser();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Email mode ────────────────────────────────────────
                if (_useEmail) ...[
                  // If a user was found — show confirm card
                  if (_foundUser != null) ...[
                    _FoundUserCard(
                      user: _foundUser!,
                      onCancel: () {
                        setState(() => _foundUser = null);
                        vm.clearResolvedUser();
                      },
                      onConfirm: vm.isLoading
                          ? null
                          : () => _onConfirmAdd(vm),
                      isLoading: vm.isLoading,
                    ),
                  ] else ...[
                    // Email input + lookup button
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      style: const TextStyle(
                          color: Color(0xFF1A1A2E), fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        hintStyle: const TextStyle(
                            color: Color(0xFFBBBBCC)),
                        filled: true,
                        fillColor: const Color(0xFFF8F8FC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFFDDDDEE))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFFDDDDEE))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF3DBFA8), width: 1.5)),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF3DBFA8), size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter an email address';
                        }
                        // Basic email validation
                        final email = v.trim();
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: 'Find Member',
                        icon: Icons.search_rounded,
                        isLoading: vm.isLoading,
                        onTap: vm.isLoading ? null : () => _onLookup(vm),
                      ),
                    ),
                  ],
                ],

                // ── UID mode ──────────────────────────────────────────
                if (!_useEmail) ...[
                  TextFormField(
                    controller: _uidCtrl,
                    autofocus: true,
                    style: const TextStyle(
                        color: Color(0xFF1A1A2E), fontSize: 14,
                        fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'e.g. CzUiPJqnbYZs…',
                      hintStyle:
                      const TextStyle(color: Color(0xFFBBBBCC)),
                      filled: true,
                      fillColor: const Color(0xFFF8F8FC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFDDDDEE))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFDDDDEE))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF3DBFA8), width: 1.5)),
                      prefixIcon: const Icon(Icons.fingerprint_rounded,
                          color: Color(0xFF3DBFA8), size: 18),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a user ID'
                        : null,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'The user ID can be found on their Profile screen → tap their ID to copy it.',
                    style: TextStyle(
                        color: Color(0xFFBBBBCC),
                        fontSize: 11,
                        height: 1.4),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: _ActionButton(
                      label: 'Add Member',
                      icon: Icons.person_add_rounded,
                      isLoading: vm.isLoading,
                      onTap: vm.isLoading
                          ? null
                          : () => _onAddByUid(vm),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Found user confirmation card ─────────────────────────────────────────────

class _FoundUserCard extends StatelessWidget {
  const _FoundUserCard({
    required this.user,
    required this.onCancel,
    required this.onConfirm,
    required this.isLoading,
  });

  final UserModel user;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;

  String get _initials {
    final parts = user.name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F9F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF3DBFA8).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3DBFA8),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                          color: Color(0xFF888899), fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Verified badge
              if (user.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Color(0xFF4CAF50), size: 12),
                      SizedBox(width: 3),
                      Text('Verified',
                          style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Confirm / Cancel buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888899),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: isLoading
                        ? const Color(0xFF3DBFA8).withOpacity(0.6)
                        : const Color(0xFF3DBFA8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : const Text(
                    'Add to Circle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFF999AAA),
              fontSize: 13,
              fontWeight:
              isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isLoading
              ? const Color(0xFF3DBFA8).withOpacity(0.6)
              : const Color(0xFF3DBFA8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}