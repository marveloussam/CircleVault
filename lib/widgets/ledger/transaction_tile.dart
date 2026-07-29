import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helpers.dart';
import '../../models/transaction_model.dart';
import '../common/status_badge.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.memberName,
    this.onTap,
    this.showCircleName = false,
    this.circleName,
  });

  final TransactionModel transaction;

  /// Display name of the member who made/received this transaction.
  /// If null, falls back to a shortened UID.
  final String? memberName;

  final VoidCallback? onTap;

  /// When shown on the home screen (across all circles), show the circle name.
  final bool showCircleName;
  final String? circleName;

  IconData get _typeIcon {
    return switch (transaction.type) {
      TransactionType.contribution => Icons.arrow_upward_rounded,
      TransactionType.payout => Icons.arrow_downward_rounded,
      TransactionType.fee => Icons.remove_circle_outline_rounded,
      TransactionType.refund => Icons.replay_rounded,
    };
  }

  Color get _iconColor {
    return switch (transaction.type) {
      TransactionType.contribution => AppColors.contribution,
      TransactionType.payout => AppColors.payout,
      TransactionType.fee => AppColors.fee,
      TransactionType.refund => AppColors.info,
    };
  }

  String get _displayName =>
      memberName ?? '${transaction.memberUid.substring(0, 6)}…';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon, color: _iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Name + badge + ref
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge.fromTransactionType(transaction.type),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (showCircleName && circleName != null) ...[
                        Text(
                          circleName!,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                      Text(
                        'Round ${transaction.roundNumber}',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 11),
                      ),
                      Text(
                        DateHelpers.timeAgo(transaction.timestamp),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.reference.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${transaction.reference}',
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.type == TransactionType.contribution ? '-' : '+'}${CurrencyFormatter.format(transaction.amountKobo)}',
                  style: TextStyle(
                    color: transaction.type == TransactionType.payout
                        ? AppColors.payout
                        : transaction.type == TransactionType.contribution
                            ? AppColors.textPrimary
                            : AppColors.fee,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateHelpers.formatShort(transaction.timestamp),
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

/// A thin divider between transaction tiles.
class TransactionDivider extends StatelessWidget {
  const TransactionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
      color: AppColors.divider,
    );
  }
}
