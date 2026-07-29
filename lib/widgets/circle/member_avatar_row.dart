import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/member_model.dart';
import '../../models/user_model.dart';

class MemberAvatarRow extends StatelessWidget {
  const MemberAvatarRow({
    super.key,
    required this.members,
    required this.userMap,
    this.currentRound = 1,
    this.maxVisible = 6,
    this.onMemberTap,
  });

  /// Ordered list of members by rotationPosition.
  final List<MemberModel> members;

  /// Map of uid → UserModel for display names / initials.
  final Map<String, UserModel> userMap;

  /// The current active round — highlights that member's slot.
  final int currentRound;

  final int maxVisible;
  final void Function(MemberModel)? onMemberTap;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxVisible).toList();
    final overflow = members.length - maxVisible;

    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final member in visible)
          _MemberAvatar(
            member: member,
            user: userMap[member.uid],
            isCurrentRecipient: member.rotationPosition == currentRound,
            onTap: onMemberTap != null ? () => onMemberTap!(member) : null,
          ),
        if (overflow > 0)
          _OverflowBubble(count: overflow),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.user,
    required this.isCurrentRecipient,
    this.onTap,
  });

  final MemberModel member;
  final UserModel? user;
  final bool isCurrentRecipient;
  final VoidCallback? onTap;

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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrentRecipient
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.surface,
                  border: Border.all(
                    color: isCurrentRecipient
                        ? AppColors.accent
                        : member.hasReceivedPayout
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.divider,
                    width: isCurrentRecipient ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: isCurrentRecipient
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Position badge
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isCurrentRecipient
                        ? AppColors.accent
                        : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${member.rotationPosition}',
                      style: TextStyle(
                        color: isCurrentRecipient
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              // Payout received checkmark
              if (member.hasReceivedPayout)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 50,
            child: Text(
              user?.name.split(' ').first ?? 'Member',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowBubble extends StatelessWidget {
  const _OverflowBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
          ),
          child: Center(
            child: Text(
              '+$count',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const SizedBox(height: 14), // space to match name label height
      ],
    );
  }
}
