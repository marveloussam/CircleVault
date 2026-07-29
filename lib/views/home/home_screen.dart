import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/common/app_shimmer.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/ledger/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      if (uid != null) {
        context.read<HomeViewModel>().init(uid);
      }
    });
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.logout,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logout,
      confirmVariant: ButtonVariant.danger,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          if (vm.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackbar.showError(
                  context, vm.errorMessage ?? AppStrings.genericError);
            });
          }

          return RefreshIndicator(
            color: const Color(0xFF00B4A6),
            backgroundColor: Colors.white,
            onRefresh: () => vm.refresh(
              context.read<AuthViewModel>().currentUser?.uid ?? '',
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroSection(vm: vm, onLogout: _logout),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),

                SliverToBoxAdapter(
                  child: _QuickActions(vm: vm),
                ),
                SliverToBoxAdapter(
                  child: _ActiveGroupsSection(vm: vm),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.vm, required this.onLogout});

  final HomeViewModel vm;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final firstName = (vm.user?.name ?? '').split(' ').first;
    final moneyIn = vm.recentTransactions
        .where((t) => t.type.toValue() == 'contribution')
        .fold<int>(0, (sum, t) => sum + t.amountKobo);
    final moneyOut = vm.recentTransactions
        .where((t) => t.type.toValue() == 'payout')
        .fold<int>(0, (sum, t) => sum + t.amountKobo);
    final nextCircle = vm.circles.isNotEmpty ? vm.circles.first : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1176B7),
            Color(0xFF00A499),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  vm.isLoading && vm.user == null
                      ? ShimmerBox(width: 180, height: 28, borderRadius: 6)
                      : RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Hi, ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: firstName.isEmpty ? 'there' : firstName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onLogout,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Wallet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Powered by Paystack',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    vm.isLoading && vm.user == null
                        ? ShimmerBox(width: 160, height: 36, borderRadius: 6)
                        : Text(
                      CurrencyFormatter.formatCompact(vm.totalSavingsKobo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _WalletStat(
                          label: 'Money In',
                          value: '+${CurrencyFormatter.formatCompact(moneyIn)}',
                          valueColor: const Color(0xFF7EFFD4),
                        ),
                        const SizedBox(width: 28),
                        _WalletStat(
                          label: 'Money Out',
                          value: '-${CurrencyFormatter.formatCompact(moneyOut)}',
                          valueColor: const Color(0xFFFF7F7F),
                          strikethrough: true,
                        ),
                        const SizedBox(width: 28),
                        if (nextCircle != null)
                          _WalletStat(
                            label: 'Next Date:',
                            value: _formatShortDate(
                                nextCircle.nextContributionDate),
                            valueColor: const Color(0xFFFFD96A),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/wallet'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: const Text(
                          'To view wallet details and withdraw →',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _WalletStat extends StatelessWidget {
  const _WalletStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.strikethrough = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
            decorationColor: valueColor,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      transform: Matrix4.translationValues(0, -24, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionItem(
            icon: Icons.download_rounded,
            label: 'History',
            onTap: () => Navigator.of(context).pushNamed('/circles'),
          ),
          _QuickActionItem(
            icon: Icons.add_rounded,
            label: 'New Group',
            onTap: () => Navigator.of(context).pushNamed('/createCircle'),
          ),
          _QuickActionItem(
            icon: Icons.groups_2_rounded,
            label: 'My Group',
            onTap: () => Navigator.of(context).pushNamed('/circles'),
          ),
          _QuickActionItem(
            icon: Icons.smart_toy_outlined,
            label: 'AI Tips',
            onTap: () => Navigator.of(context).pushNamed('/tips'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F9F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF00B4A6).withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: const Color(0xFF00B4A6), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555566),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveGroupsSection extends StatelessWidget {
  const _ActiveGroupsSection({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final activeCircles =
    vm.circles.where((c) => c.status.toValue() == 'active').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE GROUPS',
            style: TextStyle(
              color: Color(0xFF999AAA),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (vm.isLoading && vm.circles.isEmpty) ...[
            _GroupCardShimmer(),
            const SizedBox(height: 12),
            _GroupCardShimmer(),
          ] else if (activeCircles.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.groups_2_outlined,
                        color: Color(0xFFCCCCDD), size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'No active groups yet',
                      style: TextStyle(
                        color: Color(0xFF999AAA),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed('/createCircle'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4A6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '+ Create a circle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activeCircles.map((circle) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GroupCard(
                circle: circle,
                onTap: () => Navigator.of(context)
                    .pushNamed('/circle', arguments: circle.id),
              ),
            )),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.circle, required this.onTap});

  final dynamic circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = circle.totalMembers > 0
        ? (circle.currentRound / circle.totalMembers).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    circle.name,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FFF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${CurrencyFormatter.formatCompact(circle.contributionAmount)}/${circle.frequency} · ${circle.totalMembers} members',
              style: const TextStyle(
                color: Color(0xFF999AAA),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: const Color(0xFFEEEEF5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00B4A6)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MemberAvatarStack(memberUids: circle.memberUids),
                Text(
                  'Payout: Cycle ${circle.currentRound}',
                  style: const TextStyle(
                    color: Color(0xFF00B4A6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.memberUids});

  final List<String> memberUids;

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF96CEB4),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = memberUids.take(4).toList();
    final extra = memberUids.length - visible.length;

    return SizedBox(
      height: 28,
      width: (visible.length + (extra > 0 ? 1 : 0)) * 22.0 + 6,
      child: Stack(
        children: [
          ...visible.asMap().entries.map((e) => Positioned(
            left: e.key * 22.0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colors[e.key % _colors.length],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + e.key),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )),
          if (extra > 0)
            Positioned(
              left: visible.length * 22.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEEEEF5),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Color(0xFF666677),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 160, height: 16, borderRadius: 4),
          const SizedBox(height: 8),
          ShimmerBox(width: 120, height: 12, borderRadius: 4),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 6, borderRadius: 4),
          const SizedBox(height: 12),
          ShimmerBox(width: 100, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}



class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Color(0xFF00B4A6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}