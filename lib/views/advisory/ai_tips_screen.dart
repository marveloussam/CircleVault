import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';
import '../../viewmodels/ai_advisory_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/common/error_snackbar.dart';

class AiTipsScreen extends StatefulWidget {
  const AiTipsScreen({super.key});

  @override
  State<AiTipsScreen> createState() => _AiTipsScreenState();
}

class _AiTipsScreenState extends State<AiTipsScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Deferred to avoid "setState during build" assertion.
    // initState runs during the first build frame — calling notifyListeners()
    // synchronously here crashes. postFrameCallback runs after the frame settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthViewModel>().currentUser?.uid ?? '';
      final vm = context.read<AiAdvisoryViewModel>();
      vm.loadHistory(uid);
      if (vm.currentTip == null) {
        _fetchTip();
      }
    });
  }

  Future<void> _fetchTip() async {
    if (!mounted) return;
    final homeVM = context.read<HomeViewModel>();
    final vm = context.read<AiAdvisoryViewModel>();
    final user = homeVM.user;

    if (user == null) {
      AppSnackbar.showError(context, 'Profile not loaded. Try again.');
      return;
    }

    await vm.fetchNewTip(user: user, circleCount: homeVM.circles.length);

    if (!mounted) return;
    if (vm.hasError) {
      AppSnackbar.showError(
          context, vm.errorMessage ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Consumer2<HomeViewModel, AiAdvisoryViewModel>(
        builder: (context, homeVm, aiVm, _) {
          final scores = _FinancialScores.compute(
            transactions: homeVm.recentTransactions,
            circleCount: homeVm.circles.length,
            totalSavingsKobo: homeVm.totalSavingsKobo,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HeroHeader(scores: scores)),

              // Score breakdown
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    'SCORE BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF999AAA),
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: _ScoreBreakdownCard(scores: scores)),

              // Data notice if insufficient
              if (!scores.hasSufficientData)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _DataNotice(),
                  ),
                ),

              // Personalised tips
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
                  child: Text(
                    'PERSONALISED TIPS FOR YOU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF999AAA),
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _AiTipSection(
                  aiVm: aiVm,
                  onRefresh: aiVm.isLoading ? null : _fetchTip,
                ),
              ),

              SliverToBoxAdapter(child: _InsightCards(scores: scores)),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Score Model ─────────────────────────────────────────────────────────────
// Each metric is nullable. null = not enough data to calculate (shown as N/A).

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

  final int? overall; // null if < 2 contributions
  final String overallLabel;

  // Each metric: null = N/A (insufficient data)
  final int? paymentSpeed;     // requires >= 1 contribution
  final int? onTimeRate;       // requires >= 3 contributions
  final int? incomeRatio;      // always N/A — no income field in app
  final int? socialCollateral; // requires >= 1 circle

  final int contributionCount;
  final int payoutCount;
  final int circleCount;
  final int totalSavingsKobo;

  /// True when we have enough real data to show a meaningful overall score.
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

    debugPrint('[AiTipsScreen] Computing scores. '
        'contributions=$contribCount, payouts=${payouts.length}, '
        'circles=$circleCount, totalSavingsKobo=$totalSavingsKobo');

    // ── Payment Speed ─────────────────────────────────────────────────────
    // Requires at least 1 confirmed contribution. Reflects how actively
    // the user has been paying into their circles.
    // Formula: min(95, 50 + contributions * 9) — grows with each payment,
    // capped at 95 so there's always room to improve.
    final int? paymentSpeed =
    contribCount >= 1 ? math.min(95, 50 + contribCount * 9) : null;

    // ── On-Time Rate ──────────────────────────────────────────────────────
    // Requires >= 3 contributions to be statistically meaningful.
    // We don't store late flags in TransactionModel, so we use a proxy:
    // (payouts received / circles joined) × 100, bounded 70–100.
    // More circles with more payouts = higher reliability signal.
    int? onTimeRate;
    if (contribCount >= 3) {
      final reliability = circleCount > 0
          ? (payouts.length / circleCount * 50).clamp(0, 30).round()
          : 0;
      onTimeRate = math.min(100, 70 + reliability);
    }

    // ── Income Ratio ──────────────────────────────────────────────────────
    // Permanently N/A — the app has no declared income field.
    // We never show a fabricated number for this.
    const int? incomeRatio = null;

    // ── Social Collateral ──────────────────────────────────────────────────
    // Requires at least 1 circle. Reflects how trusted the user is in the
    // network: more circles + more total contributions = higher collateral.
    int? socialCollateral;
    if (circleCount >= 1) {
      socialCollateral =
          math.min(95, 40 + (circleCount * 15) + (contribCount * 3));
    }

    // ── Overall ───────────────────────────────────────────────────────────
    // Only computed when we have at least paymentSpeed + socialCollateral.
    // We skip incomeRatio (always null) from the average.
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

    debugPrint('[AiTipsScreen] Scores → '
        'overall=$overall ($overallLabel), '
        'paymentSpeed=$paymentSpeed, onTimeRate=$onTimeRate, '
        'incomeRatio=$incomeRatio (always N/A), '
        'social=$socialCollateral');

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

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.scores});
  final _FinancialScores scores;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel = '${months[now.month - 1]} ${now.year}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1A14),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white60, size: 14),
                    SizedBox(width: 4),
                    Text('Back',
                        style:
                        TextStyle(color: Colors.white60, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // AI pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A843).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFD4A843).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('AI',
                        style: TextStyle(
                            color: Color(0xFFD4A843),
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    SizedBox(width: 6),
                    Text('POWERED BY CIRCLEVAULT AI',
                        style: TextStyle(
                            color: Color(0xFFD4A843),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your Financial\nHealth',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Updated after every contribution · $monthLabel',
                style:
                const TextStyle(color: Colors.white38, fontSize: 12),
              ),

              const SizedBox(height: 24),

              // Score ring + label
              Row(
                children: [
                  _ScoreRing(score: scores.overall),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                scores.overallLabel,
                                style: const TextStyle(
                                  color: Color(0xFFD4A843),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (scores.overall != null &&
                                scores.overall! >= 70) ...[
                              const SizedBox(width: 6),
                              const Text('🏆',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _heroSubtitle(scores),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
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

  String _heroSubtitle(_FinancialScores s) {
    if (s.contributionCount == 0) {
      return 'Make your first contribution to start building your score.';
    }
    if (s.contributionCount < 3) {
      return 'Keep paying on time — your full score unlocks after 3 contributions.';
    }
    if ((s.overall ?? 0) >= 85) {
      return "You're in the top tier of CircleVault members based on payment reliability.";
    }
    if ((s.overall ?? 0) >= 70) {
      return 'Solid progress. Keep contributing consistently to boost your score.';
    }
    return 'Building your savings track record. Every contribution counts.';
  }
}

// ─── Score Ring ───────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final int? score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _RingPainter(
              progress: score != null ? score! / 100 : 0,
              trackColor: Colors.white12,
              progressColor: score != null
                  ? const Color(0xFFD4A843)
                  : Colors.white24,
              strokeWidth: 7,
            ),
          ),
          score != null
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Text('/100',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ],
          )
              : const Text('—',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

// ─── Score Breakdown Card ─────────────────────────────────────────────────────

class _ScoreBreakdownCard extends StatelessWidget {
  const _ScoreBreakdownCard({required this.scores});
  final _FinancialScores scores;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _RowData(
        emoji: '⚡',
        label: 'Payment Speed',
        value: scores.paymentSpeed,
        color: const Color(0xFF4CAF50),
        tooltip: 'Based on your contribution history',
      ),
      _RowData(
        emoji: '📅',
        label: 'On-Time Rate',
        value: scores.onTimeRate,
        color: const Color(0xFF4CAF50),
        tooltip: 'Available after 3+ contributions',
      ),
      _RowData(
        emoji: '💰',
        label: 'Income Ratio',
        value: scores.incomeRatio, // always null
        color: const Color(0xFFFFA726),
        tooltip: 'Needs income data — not available yet',
      ),
      _RowData(
        emoji: '🤝',
        label: 'Social Collateral',
        value: scores.socialCollateral,
        color: const Color(0xFF3DBFA8),
        tooltip: 'Based on your circle memberships',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              _ScoreRowWidget(row: e.value),
              if (!isLast)
                const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF0F0F8)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RowData {
  const _RowData({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.tooltip,
  });
  final String emoji;
  final String label;
  final int? value; // null = N/A
  final Color color;
  final String tooltip;
}

class _ScoreRowWidget extends StatelessWidget {
  const _ScoreRowWidget({required this.row});
  final _RowData row;

  @override
  Widget build(BuildContext context) {
    final hasData = row.value != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(row.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!hasData) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.tooltip,
                    style: const TextStyle(
                        color: Color(0xFFBBBBCC), fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: hasData ? row.value! / 100 : 0,
                backgroundColor: const Color(0xFFEEEEF5),
                valueColor: AlwaysStoppedAnimation<Color>(
                    hasData ? row.color : const Color(0xFFDDDDEE)),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              hasData ? '${row.value}%' : 'N/A',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: hasData ? row.color : const Color(0xFFCCCCDD),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Notice ─────────────────────────────────────────────────────────────

class _DataNotice extends StatelessWidget {
  const _DataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Text('ℹ️', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some scores show N/A — they need more contribution history to calculate accurately.',
              style: TextStyle(
                  color: Color(0xFF885500), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Tip Section ───────────────────────────────────────────────────────────

class _AiTipSection extends StatelessWidget {
  const _AiTipSection({required this.aiVm, required this.onRefresh});

  final AiAdvisoryViewModel aiVm;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (aiVm.isLoading && aiVm.currentTip == null) {
      return _TipCard(
        borderColor: const Color(0xFF3DBFA8),
        bgColor: const Color(0xFFE8F9F4),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF3DBFA8)),
            ),
            SizedBox(width: 12),
            Text('Generating your personalised tip…',
                style: TextStyle(
                    color: Color(0xFF3DBFA8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (aiVm.hasError && aiVm.currentTip == null) {
      return _TipCard(
        borderColor: const Color(0xFFE53935),
        bgColor: const Color(0xFFFFECEC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Could not load AI tip',
                style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              aiVm.errorMessage ?? 'Unknown error.',
              style: const TextStyle(
                  color: Color(0xFF884444), fontSize: 12, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onRefresh,
                child: const Text('Tap to retry →',
                    style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
    }

    if (aiVm.currentTip != null) {
      final tip = aiVm.currentTip!;
      return _TipCard(
        borderColor: const Color(0xFF3DBFA8),
        bgColor: const Color(0xFFE8F9F4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(AiAdvisoryViewModel.categoryEmoji(tip.category),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AiAdvisoryViewModel.categoryLabel(tip.category),
                    style: const TextStyle(
                        color: Color(0xFF2A9D8F),
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (onRefresh != null)
                  GestureDetector(
                    onTap: onRefresh,
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF3DBFA8), size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tip.tipText,
                style: const TextStyle(
                    color: Color(0xFF1A1A2E), fontSize: 13, height: 1.55)),
          ],
        ),
      );
    }

    // No tip yet
    return _TipCard(
      borderColor: const Color(0xFF3DBFA8),
      bgColor: const Color(0xFFE8F9F4),
      child: GestureDetector(
        onTap: onRefresh,
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF3DBFA8), size: 18),
            SizedBox(width: 10),
            Text('Tap to generate your first AI tip',
                style: TextStyle(
                    color: Color(0xFF3DBFA8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Insight Cards ────────────────────────────────────────────────────────────

class _InsightCards extends StatelessWidget {
  const _InsightCards({required this.scores});
  final _FinancialScores scores;

  @override
  Widget build(BuildContext context) {
    final cards = <_InsightData>[];

    // Only show insights when there's real data to base them on
    if (scores.contributionCount == 0) {
      cards.add(_InsightData(
        emoji: '🚀',
        title: 'Make Your First Contribution',
        body: 'Your financial health score builds with every payment. '
            'Complete your first contribution to start tracking your progress.',
        isWarning: false,
      ));
    } else if (scores.contributionCount < 3) {
      cards.add(_InsightData(
        emoji: '📈',
        title: 'Score Building In Progress',
        body: 'You\'ve made ${scores.contributionCount} contribution(s). '
            'After 3 contributions, more score metrics unlock. '
            'Keep going — you\'re on the right track.',
        isWarning: false,
      ));
    } else {
      // Enough data for real insights
      if ((scores.paymentSpeed ?? 0) >= 80) {
        cards.add(_InsightData(
          emoji: '✅',
          title: 'Strong Payment Record',
          body: 'You\'ve made ${scores.contributionCount} contributions '
              'across your circles. Consistent payers are more likely to be '
              'selected as trusted members in new groups.',
          isWarning: false,
        ));
      }

      if ((scores.socialCollateral ?? 0) < 60) {
        cards.add(_InsightData(
          emoji: '💡',
          title: 'Grow Your Network',
          body: 'Joining more circles increases your social collateral score '
              'and makes you eligible for higher-value groups over time.',
          isWarning: false,
        ));
      }
    }

    // Income ratio always unavailable — explain it honestly once
    cards.add(const _InsightData(
      emoji: '⚠️',
      title: 'Income Ratio Unavailable',
      body: 'This metric needs your declared income to calculate. '
          'Circle Vault doesn\'t currently store income data — '
          'this will unlock in a future update.',
      isWarning: true,
    ));

    return Column(
      children: cards
          .map((c) => _TipCard(
        borderColor: c.isWarning
            ? const Color(0xFFE53935)
            : const Color(0xFF4CAF50),
        bgColor: c.isWarning
            ? const Color(0xFFFFECEC)
            : const Color(0xFFECFDF3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(c.emoji,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.title,
                    style: TextStyle(
                      color: c.isWarning
                          ? const Color(0xFFE53935)
                          : const Color(0xFF2E7D32),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(c.body,
                style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 13,
                    height: 1.55)),
          ],
        ),
      ))
          .toList(),
    );
  }
}

class _InsightData {
  const _InsightData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.isWarning,
  });
  final String emoji;
  final String title;
  final String body;
  final bool isWarning;
}

// ─── Shared tip card shell ────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.borderColor,
    required this.bgColor,
    required this.child,
  });

  final Color borderColor;
  final Color bgColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: child,
    );
  }
}