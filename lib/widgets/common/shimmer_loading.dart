import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_sizes.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppSizes.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerTransactionItem extends StatelessWidget {
  const ShimmerTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              const ShimmerLoading(width: 48, height: 48),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: 150,
                      height: 16,
                      borderRadius: AppSizes.radiusSm,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 80,
                      height: 12,
                      borderRadius: AppSizes.radiusSm,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerLoading(
                    width: 70,
                    height: 16,
                    borderRadius: AppSizes.radiusSm,
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    width: 50,
                    height: 12,
                    borderRadius: AppSizes.radiusSm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerTransactionList extends StatelessWidget {
  final int itemCount;

  const ShimmerTransactionList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => const ShimmerTransactionItem(),
    );
  }
}

class ShimmerBalanceCard extends StatelessWidget {
  const ShimmerBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: 100,
            height: 14,
            borderRadius: AppSizes.radiusSm,
          ),
          const SizedBox(height: 12),
          ShimmerLoading(
            width: 180,
            height: 36,
            borderRadius: AppSizes.radiusSm,
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(
                child: ShimmerLoading(
                  height: 60,
                  borderRadius: AppSizes.radiusMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: ShimmerLoading(
                  height: 60,
                  borderRadius: AppSizes.radiusMd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShimmerAccountCard extends StatelessWidget {
  const ShimmerAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            const ShimmerLoading(width: 56, height: 56),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(
                    width: 120,
                    height: 16,
                    borderRadius: AppSizes.radiusSm,
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    width: 80,
                    height: 12,
                    borderRadius: AppSizes.radiusSm,
                  ),
                ],
              ),
            ),
            ShimmerLoading(
              width: 80,
              height: 20,
              borderRadius: AppSizes.radiusSm,
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerBudgetCard extends StatelessWidget {
  const ShimmerBudgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerLoading(width: 48, height: 48),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(
                        width: 120,
                        height: 16,
                        borderRadius: AppSizes.radiusSm,
                      ),
                      const SizedBox(height: 8),
                      ShimmerLoading(
                        width: 80,
                        height: 12,
                        borderRadius: AppSizes.radiusSm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ShimmerLoading(height: 8, borderRadius: AppSizes.radiusSm),
            const SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerLoading(
                  width: 80,
                  height: 12,
                  borderRadius: AppSizes.radiusSm,
                ),
                ShimmerLoading(
                  width: 60,
                  height: 12,
                  borderRadius: AppSizes.radiusSm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
