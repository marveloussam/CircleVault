import 'package:circlevault/views/circle/widget/add_member_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/enums/circle_status.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helpers.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/circle_viewmodel.dart';
import '../../widgets/circle/member_avatar_row.dart';
import '../../widgets/circle/rotation_timeline.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/status_badge.dart';

class CircleDetailScreen extends StatefulWidget {
  const CircleDetailScreen({super.key});

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  late String _circleId;
  bool _argsLoaded = false;
  Map<String, UserModel> _userMap = {};
  bool _loadingUsers = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _circleId = ModalRoute.of(context)!.settings.arguments as String;
      _argsLoaded = true;
      context.read<CircleViewModel>().watchCircle(_circleId);
    }
  }

  Future<void> _loadUsers(List<String> uids) async {
    if (_loadingUsers) return;
    setState(() => _loadingUsers = true);
    final repo = context.read<UserRepository>();
    final map = <String, UserModel>{};
    for (final uid in uids) {
      try {
        map[uid] = await repo.getUser(uid);
      } catch (_) {}
    }
    if (mounted) setState(() { _userMap = map; _loadingUsers = false; });
  }

  Future<void> _startCircle(CircleViewModel vm) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Start Circle',
      message:
          'This will activate the circle and begin the contribution schedule.',
      confirmLabel: AppStrings.startCircle,
      icon: Icons.play_circle_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    final ok = await vm.startCircle(_circleId);
    if (mounted) {
      ok
          ? AppSnackbar.showSuccess(context, 'Circle started!')
          : AppSnackbar.showError(
              context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  Future<void> _pauseCircle(CircleViewModel vm) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Pause Circle',
      message: 'Automatic contributions will be paused.',
      confirmLabel: AppStrings.pauseCircle,
      confirmVariant: ButtonVariant.danger,
      icon: Icons.pause_circle_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    await vm.updateStatus(_circleId, CircleStatus.paused);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid =
        context.read<AuthViewModel>().currentUser?.uid ?? '';

    return Consumer<CircleViewModel>(
      builder: (context, vm, _) {
        final circle = vm.currentCircle;
        final members = vm.members;

        // Lazy-load user display names when members list changes
        if (members.isNotEmpty &&
            members.any((m) => !_userMap.containsKey(m.uid))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadUsers(members.map((m) => m.uid).toList());
          });
        }

        if (circle == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme:
                  const IconThemeData(color: AppColors.textSecondary),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          );
        }

        final isAdmin = vm.isAdmin(currentUid);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              circle.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme:
                const IconThemeData(color: AppColors.textSecondary),
            actions: [
              StatusBadge.fromCircleStatus(circle.status),
              const SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Stats bar ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    _StatCell(
                      label: 'Contribution',
                      value: CurrencyFormatter.formatCompact(
                          circle.contributionAmount),
                    ),
                    _divider(),
                    _StatCell(
                      label: 'Members',
                      value:
                          '${circle.memberUids.length}/${circle.totalMembers}',
                    ),
                    _divider(),
                    _StatCell(
                      label: 'Round',
                      value:
                          '${circle.currentRound}/${circle.totalMembers}',
                    ),
                    _divider(),
                    _StatCell(
                      label: 'Next Due',
                      value: DateHelpers.formatShort(
                          circle.nextContributionDate),
                    ),
                  ],
                ),
              ),

              // ── Members ────────────────────────────────────────────
              const SectionHeader(title: AppStrings.members),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppStrings.noMembersYet,
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MemberAvatarRow(
                    members: members,
                    userMap: _userMap,
                    currentRound: circle.currentRound,
                    onMemberTap: (_) {},
                  ),
                ),

              // ── Admin: Add member ──────────────────────────────────
              if (isAdmin && !circle.isFull) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomButton(
                    label: AppStrings.addMember,
                    onPressed: () =>
                        showAddMemberSheet(context,vm:  vm, circleId: circle.id),
                    variant: ButtonVariant.outlined,
                    icon: Icons.person_add_alt_1_outlined,
                    height: 44,
                  ),
                ),
              ],

              // ── Rotation timeline ──────────────────────────────────
              const SectionHeader(title: AppStrings.rotationOrder),
              if (vm.rotationSlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Rotation order will appear once members join.',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RotationTimeline(
                    slots: vm.rotationSlots,
                    members: members,
                    userMap: _userMap,
                    currentRound: circle.currentRound,
                    contributionAmountKobo: circle.contributionAmount,
                  ),
                ),

              const SizedBox(height: 16),

              // ── View Ledger button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomButton(
                  label: AppStrings.viewLedger,
                  onPressed: () => Navigator.of(context)
                      .pushNamed('/ledger', arguments: _circleId),
                  variant: ButtonVariant.secondary,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(height: 12),

              // ── Admin actions ──────────────────────────────────────
              if (isAdmin) ...[
                if (circle.status == CircleStatus.pending)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      label: AppStrings.startCircle,
                      onPressed: () => _startCircle(vm),
                      icon: Icons.play_arrow_rounded,
                    ),
                  ),
                if (circle.status == CircleStatus.active)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      label: AppStrings.pauseCircle,
                      onPressed: () => _pauseCircle(vm),
                      variant: ButtonVariant.danger,
                      icon: Icons.pause_rounded,
                    ),
                  ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }


  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
