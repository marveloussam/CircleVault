import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helpers.dart';

/// Hero card at the top of the HomeScreen showing the user's greeting,
/// total savings across all circles, and active circle count.
class SavingsSummaryCard extends StatelessWidget {
  const SavingsSummaryCard({
    super.key,
    required this.userName,
    required this.totalSavingsKobo,
    required this.activeCircleCount,
    required this.totalCircleCount,
  });

  final String userName;
  final int totalSavingsKobo;
  final int activeCircleCount;
  final int totalCircleCount;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName => userName.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E3A),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting,',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _firstName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Date badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateHelpers.formatDate(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total savings label
          const Text(
            'TOTAL SAVINGS',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalSavingsKobo),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatPill(
                icon: Icons.circle_outlined,
                label: '$totalCircleCount ${totalCircleCount == 1 ? 'circle' : 'circles'}',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.bolt_rounded,
                label: '$activeCircleCount active',
                highlight: activeCircleCount > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withOpacity(0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? AppColors.accent.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight ? AppColors.accent : AppColors.textHint,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.accent : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
