import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/ledger_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Wallet Screen
// ─────────────────────────────────────────────────────────────────────────────

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewModel, AuthViewModel>(
      builder: (context, homeVm, authVm, _) {
        final user = homeVm.user;
        final circles = homeVm.circles;
        final transactions = homeVm.recentTransactions;

        final totalReceived = transactions
            .where((t) => t.type.toValue() == 'payout')
            .fold<int>(0, (s, t) => s + t.amountKobo);

        final totalContributed = transactions
            .where((t) => t.type.toValue() == 'contribution')
            .fold<int>(0, (s, t) => s + t.amountKobo);

        // Build upcoming activity from circles
        final upcoming = _buildUpcomingActivity(circles);

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F7),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _WalletHero(
                  balance: homeVm.totalSavingsKobo,
                  totalReceived: totalReceived,
                  totalContributed: totalContributed,
                  onWithdraw: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WithdrawScreen(
                        balanceKobo: homeVm.totalSavingsKobo,
                        userName: user?.name ?? '',
                        upcomingDebitKobo: upcoming
                            .where((a) => a.type == _ActivityType.contribution)
                            .fold<int>(0, (s, a) => s + a.amountKobo),
                      ),
                    ),
                  ),
                  onStatement: () {},
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'UPCOMING WALLET ACTIVITY',
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                ),
              ),
              SliverToBoxAdapter(
                child: upcoming.isEmpty
                    ? const _EmptyUpcoming()
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: upcoming
                        .map((a) => Padding(
                      padding:
                      const EdgeInsets.only(bottom: 10),
                      child: _ActivityTile(activity: a),
                    ))
                        .toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'WALLET TRANSACTION HISTORY',
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: transactions.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(
                            color: Color(0xFF999AAA), fontSize: 14),
                      ),
                    ),
                  )
                      : Column(
                    children: transactions.asMap().entries.map((e) {
                      final t = e.value;
                      final isLast =
                          e.key == transactions.length - 1;
                      final isPayout = t.type.toValue() == 'payout';
                      return Column(
                        children: [
                          _HistoryTile(
                            emoji: isPayout ? '💰' : '🏦',
                            title: isPayout
                                ? 'Payout received'
                                : 'Contribution paid',
                            subtitle:
                            'Auto-disbursed by system',
                            amountKobo: t.amountKobo,
                            isCredit: isPayout,
                            date: _formatDate(t.timestamp),
                          ),
                          if (!isLast)
                            const Divider(
                                height: 1,
                                indent: 60,
                                color: Color(0xFFF0F0F8)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  List<_UpcomingActivity> _buildUpcomingActivity(List<dynamic> circles) {
    final list = <_UpcomingActivity>[];
    for (final c in circles) {
      if (c.status.toValue() != 'active') continue;
      list.add(_UpcomingActivity(
        type: _ActivityType.contribution,
        title: 'Contribution Due',
        subtitle:
        '${c.name} · ${_formatShortDate(c.nextContributionDate)}',
        amountKobo: c.contributionAmount,
      ));
    }
    return list;
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}';
  }

  static String _formatShortDate(DateTime? dt) {
    if (dt == null) return '';
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.balance,
    required this.totalReceived,
    required this.totalContributed,
    required this.onWithdraw,
    required this.onStatement,
  });

  final int balance;
  final int totalReceived;
  final int totalContributed;
  final VoidCallback onWithdraw;
  final VoidCallback onStatement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1176B7), Color(0xFF00A499)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back nav
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('Back',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'MY CIRCLEVAULT WALLET',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Available balance · Backed by Paystack',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'TOTAL RECEIVED',
                      value:
                      '+${CurrencyFormatter.format(totalReceived)}',
                      valueColor: const Color(0xFF4DD0C4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'TOTAL CONTRIBUTED',
                      value:
                      '+${CurrencyFormatter.format(totalContributed)}',
                      valueColor: const Color(0xFF4DD0C4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _HeroButton(
                      icon: Icons.arrow_upward_rounded,
                      label: 'WITHDRAW',
                      isPrimary: true,
                      onTap: onWithdraw,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'STATEMENT',
                      isPrimary: false,
                      onTap: onStatement,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17,
                color: isPrimary
                    ? const Color(0xFF1176B7)
                    : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isPrimary ? const Color(0xFF1176B7) : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming activity ────────────────────────────────────────────────────────

enum _ActivityType { contribution, payout }

class _UpcomingActivity {
  const _UpcomingActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amountKobo,
  });
  final _ActivityType type;
  final String title;
  final String subtitle;
  final int amountKobo;
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final _UpcomingActivity activity;

  @override
  Widget build(BuildContext context) {
    final isContrib = activity.type == _ActivityType.contribution;
    final borderColor = isContrib
        ? const Color(0xFFFFA726)
        : const Color(0xFF3DBFA8);
    final bgColor = isContrib
        ? const Color(0xFFFFF8EC)
        : const Color(0xFFECFFF8);
    final amountColor = isContrib
        ? const Color(0xFFE65100)
        : const Color(0xFF2A9D8F);
    final amountPrefix = isContrib ? '−' : '+';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          Text(isContrib ? '💸' : '💰',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(activity.subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888899))),
              ],
            ),
          ),
          Text(
            '$amountPrefix${CurrencyFormatter.format(activity.amountKobo)}',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amountColor),
          ),
        ],
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('No upcoming activity',
            style: TextStyle(color: Color(0xFF999AAA), fontSize: 14)),
      ),
    );
  }
}

// ─── History tile ─────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.amountKobo,
    required this.isCredit,
    required this.date,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final int amountKobo;
  final bool isCredit;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text('$date · $subtitle',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888899))),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '−'}${CurrencyFormatter.format(amountKobo)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCredit
                  ? const Color(0xFF2A9D8F)
                  : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.padding});
  final String label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF999AAA),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdraw Screen
// ─────────────────────────────────────────────────────────────────────────────

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({
    super.key,
    required this.balanceKobo,
    required this.userName,
    required this.upcomingDebitKobo,
  });

  final int balanceKobo;
  final String userName;
  final int upcomingDebitKobo;

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountCtr = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int get _availableKobo =>
      (widget.balanceKobo - widget.upcomingDebitKobo).clamp(0, widget.balanceKobo);

  @override
  void dispose() {
    _amountCtr.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDEE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Confirm Withdrawal',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              'Sending ₦${_amountCtr.text} to your GTBank account ending ****8821',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF888899), height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1176B7), Color(0xFF00A499)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Confirm & Send',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: Color(0xFF555566)),
                        SizedBox(width: 4),
                        Text('Back to Wallet',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF555566))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Text('Withdraw to Bank',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F9F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF3DBFA8).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('WALLET BALANCE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3DBFA8),
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(
                                      widget.balanceKobo),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A2E)),
                                ),
                              ],
                            ),
                            Container(
                              width: 52,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1176B7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Icon(Icons.credit_card_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Amount field
                      const Text('Amount to Withdraw (₦)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333344))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountCtr,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            fontSize: 16, color: Color(0xFF1A1A2E)),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: const TextStyle(
                              color: Color(0xFFBBBBCC)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
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
                                  color: Color(0xFF1176B7), width: 1.5)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE53935))),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter an amount';
                          }
                          final kobo = (int.tryParse(v) ?? 0) * 100;
                          if (kobo <= 0) return 'Enter a valid amount';
                          if (kobo > _availableKobo) {
                            return 'Amount exceeds available balance after reservations';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Withdraw To
                      const Text('Withdraw To',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333344))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFDDDDEE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F2FF),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Color(0xFF1176B7),
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text('Guaranty Trust Bank',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A2E))),
                                  const SizedBox(height: 2),
                                  Text(
                                    '****8821 · ${widget.userName.isEmpty ? 'Account holder' : widget.userName}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888899)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFFCCCCDD), size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Warning note
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFA726)
                                  .withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text('Note on Withdrawals',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE65100))),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can only withdraw funds that are NOT already scheduled as upcoming group contributions. '
                                        '${CurrencyFormatter.format(widget.upcomingDebitKobo)} is currently reserved for upcoming group debits.',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF555566),
                                        height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // CTA
            Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: GestureDetector(
                onTap: _confirm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1176B7), Color(0xFF00A499)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Confirm Withdrawal →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}