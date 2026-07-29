import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/circle_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CircleListScreen extends StatefulWidget {
  const CircleListScreen({super.key});

  @override
  State<CircleListScreen> createState() => _CircleListScreenState();
}

class _CircleListScreenState extends State<CircleListScreen> {
  // Filter tabs: 0=All, 1=Active, 2=Pending, 3=Completed
  int _filterIndex = 0;

  static const _filters = ['All', 'Active', 'Pending', 'Completed'];

  List<CircleModel> _filtered(List<CircleModel> circles) {
    switch (_filterIndex) {
      case 1:
        return circles.where((c) => c.status.toValue() == 'active').toList();
      case 2:
        return circles.where((c) => c.status.toValue() == 'pending').toList();
      case 3:
        return circles.where((c) => c.status.toValue() == 'completed').toList();
      default:
        return circles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          final filtered = _filtered(vm.circles);

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Groups',
                        style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed('/createCircle'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3DBFA8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter chips ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final isSelected = _filterIndex == i;
                      // Count label for "All"
                      final label = i == 0
                          ? 'All (${vm.circles.length})'
                          : _filters[i];
                      return Padding(
                        padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3DBFA8)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3DBFA8)
                                    : const Color(0xFFDDDDEE),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF888899),
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // ── Circle cards list ────────────────────────────────────
                Expanded(
                  child: vm.isLoading && vm.circles.isEmpty
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3DBFA8),
                      strokeWidth: 2,
                    ),
                  )
                      : filtered.isEmpty
                      ? _EmptyState(onCreateTap: () {
                    Navigator.of(context).pushNamed('/createCircle');
                  })
                      : RefreshIndicator(
                    color: const Color(0xFF3DBFA8),
                    backgroundColor: Colors.white,
                    onRefresh: () => vm.refresh(
                      context
                          .read<AuthViewModel>()
                          .currentUser
                          ?.uid ??
                          '',
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => Padding(
                        padding:
                        const EdgeInsets.only(bottom: 16),
                        child: _CircleCard(
                          circle: filtered[i],
                          onTap: () => Navigator.of(context)
                              .pushNamed('/circle',
                              arguments: filtered[i].id),
                          onLedgerTap: () =>
                              Navigator.of(context).pushNamed(
                                  '/ledger',
                                  arguments: filtered[i].id),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Circle Card ──────────────────────────────────────────────────────────────

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.circle,
    required this.onTap,
    required this.onLedgerTap,
  });

  final CircleModel circle;
  final VoidCallback onTap;
  final VoidCallback onLedgerTap;

  @override
  Widget build(BuildContext context) {
    final status = circle.status.toValue();
    final progress = circle.totalMembers > 0
        ? (circle.currentRound / circle.totalMembers).clamp(0.0, 1.0)
        : 0.0;

    // Pool = contributionAmount × totalMembers
    final poolKobo = circle.contributionAmount * circle.totalMembers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Name + Status badge ──────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${circle.name} 🔥',
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${CurrencyFormatter.formatCompact(circle.contributionAmount)}/month · ${circle.totalMembers} members · Cycle ${circle.currentRound}/${circle.totalMembers}',
                          style: const TextStyle(
                            color: Color(0xFF999AAA),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: status),
                ],
              ),

              const SizedBox(height: 14),

              // ── Row 2: Stats — Pool | Your Turn | Next Due ───────────
              IntrinsicHeight(
                child: Row(
                  children: [
                    _StatCell(
                      label: 'POOL',
                      value: CurrencyFormatter.formatCompact(poolKobo),
                      valueColor: const Color(0xFF1A1A2E),
                    ),
                    _VerticalDivider(),
                    _StatCell(
                      label: 'YOUR TURN',
                      value: 'Cycle ${circle.currentRound + 1}',
                      valueColor: const Color(0xFF3DBFA8),
                    ),
                    _VerticalDivider(),
                    _StatCell(
                      label: 'NEXT DUE',
                      value: _formatShortDate(circle.nextContributionDate),
                      valueColor: const Color(0xFFFF8C42),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Progress bar ─────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  backgroundColor: const Color(0xFFEEEEF5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3DBFA8)),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 14),

              // ── Row 3: Avatar stack + ledger link ────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MemberAvatarStack(memberUids: circle.memberUids),
                  GestureDetector(
                    onTap: onLedgerTap,
                    child: const Text(
                      'Tap to view ledger →',
                      style: TextStyle(
                        color: Color(0xFF3DBFA8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  String _formatShortDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (status) {
      case 'active':
        dotColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFECFDF3);
        textColor = const Color(0xFF4CAF50);
        label = 'Active';
        icon = null;
        break;
      case 'pending':
        dotColor = const Color(0xFFFFA726);
        bgColor = const Color(0xFFFFF8EC);
        textColor = const Color(0xFFFFA726);
        label = '2 Pending';
        icon = Icons.warning_amber_rounded;
        break;
      case 'paused':
        dotColor = const Color(0xFF999AAA);
        bgColor = const Color(0xFFF2F2F7);
        textColor = const Color(0xFF999AAA);
        label = 'Paused';
        icon = null;
        break;
      case 'completed':
        dotColor = const Color(0xFF29B6F6);
        bgColor = const Color(0xFFE8F4FD);
        textColor = const Color(0xFF29B6F6);
        label = 'Completed';
        icon = null;
        break;
      default:
        dotColor = const Color(0xFF999AAA);
        bgColor = const Color(0xFFF2F2F7);
        textColor = const Color(0xFF999AAA);
        label = status;
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon != null
              ? Icon(icon, color: dotColor, size: 12)
              : Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Cell ────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBBBBCC),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vertical Divider ─────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      color: const Color(0xFFEEEEF5),
    );
  }
}

// ─── Member Avatar Stack ──────────────────────────────────────────────────────

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.memberUids});

  final List<String> memberUids;

  // Matches the colorful avatars in the design: teal, orange, purple, red, dark
  static const _colors = [
    Color(0xFF3DBFA8), // teal
    Color(0xFFFF8C42), // orange
    Color(0xFF9B59B6), // purple
    Color(0xFFE53935), // red
    Color(0xFF1A6B72), // dark teal
  ];

  @override
  Widget build(BuildContext context) {
    final visible = memberUids.take(4).toList();
    final extra = memberUids.length - visible.length;
    const avatarSize = 30.0;
    const overlap = 20.0;
    final totalWidth =
        visible.length * overlap + (avatarSize - overlap) + (extra > 0 ? overlap : 0);

    return SizedBox(
      height: avatarSize,
      width: totalWidth.clamp(avatarSize, double.infinity),
      child: Stack(
        children: [
          ...visible.asMap().entries.map((e) => Positioned(
            left: e.key * overlap,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colors[e.key % _colors.length],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + e.key), // A, B, C, D
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
              left: visible.length * overlap,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3DBFA8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F9F4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                color: Color(0xFF3DBFA8),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No groups here yet',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start a savings circle with\nfriends or family.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF999AAA),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCreateTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DBFA8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '+ Create a circle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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