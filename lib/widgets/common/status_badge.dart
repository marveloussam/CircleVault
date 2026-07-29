import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/circle_status.dart';
import '../../core/enums/transaction_type.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge._({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  factory StatusBadge.fromCircleStatus(CircleStatus status) {
    return switch (status) {
      CircleStatus.active => StatusBadge._(
          label: 'Active',
          color: AppColors.primary,
          backgroundColor: AppColors.activeBadge,
        ),
      CircleStatus.pending => StatusBadge._(
          label: 'Pending',
          color: AppColors.warning,
          backgroundColor: AppColors.warningLight,
        ),
      CircleStatus.completed => StatusBadge._(
          label: 'Completed',
          color: AppColors.info,
          backgroundColor: AppColors.infoLight,
        ),
      CircleStatus.paused => StatusBadge._(
          label: 'Paused',
          color: AppColors.textSecondary,
          backgroundColor: AppColors.background,
        ),
    };
  }

  factory StatusBadge.fromTransactionType(TransactionType type) {
    return switch (type) {
      TransactionType.contribution => StatusBadge._(
          label: 'Contribution',
          color: AppColors.success,
          backgroundColor: AppColors.successLight,
        ),
      TransactionType.payout => StatusBadge._(
          label: 'Payout',
          color: AppColors.payout,
          backgroundColor: AppColors.accentLight,
        ),
      TransactionType.fee => StatusBadge._(
          label: 'Fee',
          color: AppColors.error,
          backgroundColor: AppColors.errorLight,
        ),
      TransactionType.refund => StatusBadge._(
          label: 'Refund',
          color: AppColors.info,
          backgroundColor: AppColors.infoLight,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
