import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helpers.dart';
import '../../models/circle_model.dart';
import '../common/status_badge.dart';

class CircleCard extends StatelessWidget {
  const CircleCard({
    super.key,
    required this.circle,
    required this.onTap,
    this.memberCount,
  });

  final CircleModel circle;
  final VoidCallback onTap;
  final int? memberCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — name + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    circle.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                StatusBadge.fromCircleStatus(circle.status),
              ],
            ),
            const SizedBox(height: 12),

            // Contribution amount
            Text(
              CurrencyFormatter.format(circle.contributionAmount),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '/ ${circle.frequency}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),

            const Spacer(),

            // Footer — members + round
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  icon: Icons.people_outline,
                  label: '${circle.memberUids.length}/${circle.totalMembers}',
                ),
                _InfoChip(
                  icon: Icons.rotate_right_rounded,
                  label: 'Round ${circle.currentRound}',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Next contribution date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textHint,
                  size: 11,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next: ${DateHelpers.formatShort(circle.nextContributionDate)}',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textHint, size: 12),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
