import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

/// Displayed at the top of the LedgerScreen showing total contributed,
/// total paid out, and transaction count for the circle.
class LedgerSummaryCard extends StatelessWidget {
  const LedgerSummaryCard({
    super.key,
    required this.totalContributedKobo,
    required this.totalPaidOutKobo,
    required this.transactionCount,
    required this.circleName,
  });

  final int totalContributedKobo;
  final int totalPaidOutKobo;
  final int transactionCount;
  final String circleName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            circleName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total In',
                  value: CurrencyFormatter.formatCompact(totalContributedKobo),
                  color: AppColors.contribution,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Total Out',
                  value: CurrencyFormatter.formatCompact(totalPaidOutKobo),
                  color: AppColors.payout,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Transactions',
                  value: '$transactionCount',
                  color: AppColors.info,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
