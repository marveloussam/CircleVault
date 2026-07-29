import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/member_model.dart';
import '../../models/rotation_slot_model.dart';
import '../../models/user_model.dart';

/// Vertical timeline showing each round's recipient and disbursement status.
class RotationTimeline extends StatelessWidget {
  const RotationTimeline({
    super.key,
    required this.slots,
    required this.members,
    required this.userMap,
    required this.currentRound,
    required this.contributionAmountKobo,
  });

  final List<RotationSlotModel> slots;
  final List<MemberModel> members;
  final Map<String, UserModel> userMap;
  final int currentRound;
  final int contributionAmountKobo;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Center(
        child: Text(
          'Rotation order not set yet.',
          style: TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isLast = index == slots.length - 1;
        final isCurrent = slot.roundNumber == currentRound;
        final isPast = slot.roundNumber < currentRound;
        final user = userMap[slot.recipientUid];
        final totalPayout = contributionAmountKobo * members.length;

        return _TimelineRow(
          slot: slot,
          user: user,
          isCurrent: isCurrent,
          isPast: isPast,
          isLast: isLast,
          totalPayoutKobo: totalPayout,
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.slot,
    required this.user,
    required this.isCurrent,
    required this.isPast,
    required this.isLast,
    required this.totalPayoutKobo,
  });

  final RotationSlotModel slot;
  final UserModel? user;
  final bool isCurrent;
  final bool isPast;
  final bool isLast;
  final int totalPayoutKobo;

  String get _initials {
    final name = user?.name ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = slot.disbursed
        ? AppColors.success
        : isCurrent
            ? AppColors.accent
            : isPast
                ? AppColors.textHint
                : AppColors.divider;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                      color: isCurrent ? AppColors.accent : Colors.transparent,
                      width: isCurrent ? 2 : 0,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: slot.disbursed
                      ? const Icon(Icons.check, color: Colors.white, size: 11)
                      : isCurrent
                          ? const Icon(Icons.play_arrow,
                              color: AppColors.primary, size: 11)
                          : null,
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isPast || slot.disbursed
                          ? AppColors.success.withOpacity(0.4)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.accent.withOpacity(0.07)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? AppColors.accent.withOpacity(0.3) : AppColors.divider,
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: isCurrent ? AppColors.accent : AppColors.divider,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + round label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown Member',
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCurrent
                              ? 'Current round'
                              : 'Round ${slot.roundNumber}',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payout amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatCompact(totalPayoutKobo),
                        style: TextStyle(
                          color: slot.disbursed
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (slot.disbursed)
                        const Text(
                          'Paid ✓',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
