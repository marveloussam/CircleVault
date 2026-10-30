import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_snackbar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.logout,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logout,
      confirmVariant: ButtonVariant.danger,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer2<HomeViewModel, AuthViewModel>(
        builder: (context, homeVm, authVm, _) {
          final user = homeVm.user;
          final uid = authVm.currentUser?.uid ?? '';
          final circles = homeVm.circles;
          final activeCount =
              circles.where((c) => c.status.toValue() == 'active').length;
          final hasCard = user?.hasLinkedCard ?? false;

          // Member since — derived from user.createdAt
          final memberSince = user?.createdAt != null
              ? _formatMemberSince(user!.createdAt)
              : 'Jan 2026';

          return CustomScrollView(
            slivers: [
              // ── Hero ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ProfileHero(
                  name: user?.name ?? '',
                  uid: uid,
                  memberSince: memberSince,
                  activeCount: activeCount,
                  isVerified: user?.isVerified ?? false,
                ),
              ),

              // ── AI Financial Health card ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _AiHealthCard(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/tips'),
                  ),
                ),
              ),

              // ── Account Settings section label ───────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    'ACCOUNT SETTINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF999AAA),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // ── Flat menu list ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _FlatMenuList(
                  items: [
                    _FlatMenuItem(
                      iconEmoji: '👤',
                      iconBg: const Color(0xFFE8F2FF),
                      label: 'Edit Profile',
                      onTap: () =>
                          _showEditNameSheet(context, user?.name ?? ''),
                    ),
                    _FlatMenuItem(
                      iconEmoji: '🏦',
                      iconBg: const Color(0xFFE8F9F4),
                      label: 'Bank Account',
                      subtitle: hasCard ? null : null,
                      onTap: () => AppSnackbar.showInfo(
                          context, 'Bank account setup coming soon.'),
                    ),
                    _FlatMenuItem(
                      iconEmoji: '💳',
                      iconBg: const Color(0xFFFFF4E5),
                      label: hasCard
                          ? 'Payment Card (Visa · ****4432)'
                          : 'Payment Card',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/addCard'),
                    ),
                    _FlatMenuItem(
                      iconEmoji: '🔔',
                      iconBg: const Color(0xFFF3E8FF),
                      label: 'Notifications',
                      onTap: () => AppSnackbar.showInfo(
                          context, 'Notification settings coming soon.'),
                    ),
                    _FlatMenuItem(
                      iconEmoji: '🔒',
                      iconBg: const Color(0xFFE8F9F4),
                      label: 'Security',
                      onTap: () => AppSnackbar.showInfo(
                          context, 'Security settings coming soon.'),
                    ),
                    _FlatMenuItem(
                      iconEmoji: '⭐',
                      iconBg: const Color(0xFFFFF4E5),
                      label: 'Rate Circle Vault',
                      onTap: () {},
                    ),
                    _FlatMenuItem(
                      iconEmoji: '❓',
                      iconBg: const Color(0xFFE8F2FF),
                      label: 'Help & FAQ',
                      onTap: () => AppSnackbar.showInfo(
                          context, 'Help centre coming soon.'),
                    ),
                  ],
                ),
              ),

              // ── Log out button ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Color(0xFFE53935), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Version footer ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Circle Vault v1.0.0',
                      style: TextStyle(
                          color: const Color(0xFF888899).withOpacity(0.6),
                          fontSize: 11),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  String _formatMemberSince(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showEditNameSheet(BuildContext context, String currentName) {
    final ctr = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text('Edit Name',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            TextField(
              controller: ctr,
              autofocus: true,
              style:
              const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Full name',
                hintStyle: const TextStyle(color: Color(0xFFBBBBCC)),
                filled: true,
                fillColor: const Color(0xFFF8F8FC),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFFDDDDEE))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFFDDDDEE))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF3DBFA8), width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  AppSnackbar.showSuccess(
                      context, 'Name update coming soon.');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3DBFA8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Save Changes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.uid,
    required this.memberSince,
    required this.activeCount,
    required this.isVerified,
  });

  final String name;
  final String uid;
  final String memberSince;
  final int activeCount;
  final bool isVerified;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A7A82),
            Color(0xFF3DBFA8),
            Color(0xFF2AB8A0),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.7), width: 3),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name.isEmpty ? 'Loading…' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Member since $memberSince · $activeCount Active ${activeCount == 1 ? 'Group' : 'Groups'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BadgePill(label: 'Consistent Payer', emoji: '🏆'),
                  const SizedBox(width: 10),
                  _BadgePill(label: 'Trusted Member', emoji: '⭐'),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (uid.isEmpty) return;
                  Clipboard.setData(ClipboardData(text: uid));
                  AppSnackbar.showSuccess(
                      context, 'User ID copied to clipboard');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fingerprint_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        uid.isEmpty
                            ? 'Loading…'
                            : 'ID: ${uid.substring(0, uid.length > 14 ? 14 : uid.length)}…',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded,
                          color: Colors.white60, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Badge Pill ───────────────────────────────────────────────────────────────

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.emoji});

  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: Colors.white.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Financial Health Card (UPDATED with real data) ──────────────────────

class _AiHealthCard extends StatelessWidget {
  const _AiHealthCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeVm, _) {
        // Compute scores using the same logic as AiTipsScreen
        final scores = _FinancialScores.compute(
          transactions: homeVm.recentTransactions,
          circleCount: homeVm.circles.length,
          totalSavingsKobo: homeVm.totalSavingsKobo,
        );

        final hasData = scores.overall != null;
        final scoreText = hasData ? '${scores.overall}/100' : '--/100';
        final labelText = hasData ? scores.overallLabel : 'Building Profile';
        final trophyEmoji = hasData && scores.overall! >= 70 ? '🏆' : '📊';

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Financial Health',
                        style: TextStyle(
                          color: Color(0xFFD4A843),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'Score: $scoreText · $labelText',
                            style: const TextStyle(
                              color: Color(0xFF888899),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trophyEmoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF555566),
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Financial Scores (copy from AiTipsScreen) ──────────────────────────────

class _FinancialScores {
  const _FinancialScores({
    required this.overall,
    required this.overallLabel,
    required this.paymentSpeed,
    required this.onTimeRate,
    required this.incomeRatio,
    required this.socialCollateral,
    required this.contributionCount,
    required this.payoutCount,
    required this.circleCount,
    required this.totalSavingsKobo,
  });

  final int? overall;
  final String overallLabel;
  final int? paymentSpeed;
  final int? onTimeRate;
  final int? incomeRatio;
  final int? socialCollateral;
  final int contributionCount;
  final int payoutCount;
  final int circleCount;
  final int totalSavingsKobo;

  bool get hasSufficientData => contributionCount >= 3;

  static _FinancialScores compute({
    required List<TransactionModel> transactions,
    required int circleCount,
    required int totalSavingsKobo,
  }) {
    final contributions = transactions
        .where((t) => t.type.toValue() == 'contribution')
        .toList();
    final payouts =
    transactions.where((t) => t.type.toValue() == 'payout').toList();
    final contribCount = contributions.length;

    final int? paymentSpeed =
    contribCount >= 1 ? math.min(95, 50 + contribCount * 9) : null;

    int? onTimeRate;
    if (contribCount >= 3) {
      final reliability = circleCount > 0
          ? (payouts.length / circleCount * 50).clamp(0, 30).round()
          : 0;
      onTimeRate = math.min(100, 70 + reliability);
    }

    const int? incomeRatio = null;

    int? socialCollateral;
    if (circleCount >= 1) {
      socialCollateral =
          math.min(95, 40 + (circleCount * 15) + (contribCount * 3));
    }

    int? overall;
    String overallLabel = 'Not enough data yet';

    final availableScores = [
      paymentSpeed,
      onTimeRate,
      socialCollateral,
    ].whereType<int>().toList();

    if (availableScores.isNotEmpty && contribCount >= 1) {
      overall =
          (availableScores.fold(0, (s, v) => s + v) / availableScores.length)
              .round()
              .clamp(0, 100);

      if (overall >= 85) {
        overallLabel = 'Excellent Saver';
      } else if (overall >= 70) {
        overallLabel = 'Good Progress';
      } else if (overall >= 55) {
        overallLabel = 'Building Up';
      } else {
        overallLabel = 'Getting Started';
      }
    }

    return _FinancialScores(
      overall: overall,
      overallLabel: overallLabel,
      paymentSpeed: paymentSpeed,
      onTimeRate: onTimeRate,
      incomeRatio: incomeRatio,
      socialCollateral: socialCollateral,
      contributionCount: contribCount,
      payoutCount: payouts.length,
      circleCount: circleCount,
      totalSavingsKobo: totalSavingsKobo,
    );
  }
}

// ─── Flat Menu List ───────────────────────────────────────────────────────────

class _FlatMenuList extends StatelessWidget {
  const _FlatMenuList({required this.items});

  final List<_FlatMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 0,
                  color: Color(0xFFF0F0F8),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FlatMenuItem extends StatelessWidget {
  const _FlatMenuItem({
    required this.iconEmoji,
    required this.iconBg,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final String iconEmoji;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child:
                Text(iconEmoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF999AAA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCCCCDD), size: 20),
          ],
        ),
      ),
    );
  }
}