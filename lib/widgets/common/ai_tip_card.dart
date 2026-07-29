import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/ai_tip_model.dart';
import '../../viewmodels/ai_advisory_viewmodel.dart';

class AiTipCard extends StatelessWidget {
  const AiTipCard({
    super.key,
    required this.tip,
    this.onDismiss,
    this.onRefresh,
    this.isLoading = false,
    this.isCompact = false,
  });

  final AiTipModel tip;
  final VoidCallback? onDismiss;
  final VoidCallback? onRefresh;
  final bool isLoading;

  /// Compact mode for home screen preview.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isCompact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.12),
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — category + dismiss
            Row(
              children: [
                Text(
                  AiAdvisoryViewModel.categoryEmoji(tip.category),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AiAdvisoryViewModel.categoryLabel(tip.category),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // AI badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onDismiss != null && !isCompact) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Tip text
            isLoading
                ? const _LoadingTipText()
                : Text(
                    tip.tipText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    maxLines: isCompact ? 3 : null,
                    overflow:
                        isCompact ? TextOverflow.ellipsis : TextOverflow.visible,
                  ),

            if (!isCompact) ...[
              const SizedBox(height: 14),
              // Footer — refresh button
              if (onRefresh != null)
                GestureDetector(
                  onTap: isLoading ? null : onRefresh,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: isLoading
                            ? AppColors.textHint
                            : AppColors.accent,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLoading ? 'Generating…' : 'Get new tip',
                        style: TextStyle(
                          color: isLoading
                              ? AppColors.textHint
                              : AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingTipText extends StatelessWidget {
  const _LoadingTipText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: 220,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: 160,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Placeholder card shown when no tip has been generated yet.
class AiTipPlaceholder extends StatelessWidget {
  const AiTipPlaceholder({super.key, required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGenerate,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('💡', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get your AI financial tip',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Personalised advice based on your savings activity.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
