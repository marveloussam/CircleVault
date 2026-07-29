import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// Light-mode shimmer box — uses light grey base/highlight.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CircleCardShimmer extends StatelessWidget {
  const CircleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: 210,
        height: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 14,
                color: AppColors.shimmerBase),
            const SizedBox(height: 10),
            Container(width: 80, height: 10,
                color: AppColors.shimmerBase),
            const Spacer(),
            Container(width: 100, height: 10,
                color: AppColors.shimmerBase),
          ],
        ),
      ),
    );
  }
}

class TransactionTileShimmer extends StatelessWidget {
  const TransactionTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                color: AppColors.shimmerBase,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, color: AppColors.shimmerBase),
                  const SizedBox(height: 6),
                  Container(
                      width: 120, height: 10,
                      color: AppColors.shimmerBase),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 70, height: 14,
                color: AppColors.shimmerBase),
          ],
        ),
      ),
    );
  }
}
