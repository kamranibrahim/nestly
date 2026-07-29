import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small inline shimmer used inside buttons/actions.
class NestShimmerCircle extends StatelessWidget {
  const NestShimmerCircle({
    super.key,
    this.size = 18,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: size, height: size, borderRadius: 999);
  }
}
/// A gentle shimmer effect for loading states.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * value, 0),
              end: Alignment(1.0 + 2.0 * value, 0),
              colors: const [
                Color(0xFFEEEEF0),
                Color(0xFFF7F7F8),
                Color(0xFFEEEEF0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder that mimics a list of NestCards.
class NestLoadingSkeleton extends StatelessWidget {
  const NestLoadingSkeleton({
    super.key,
    this.itemCount = 4,
    this.hasTitle = false,
  });

  final int itemCount;
  final bool hasTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            const ShimmerBox(width: 120, height: 18, borderRadius: 6),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < itemCount; i++) ...[
            _SkeletonCard(index: i),
            if (i < itemCount - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 80.0 + (index % 3) * 40,
            height: 14,
          ),
          const SizedBox(height: 10),
          const ShimmerBox(height: 12),
          const SizedBox(height: 8),
          ShimmerBox(
            width: 140.0 + (index % 2) * 60,
            height: 12,
          ),
        ],
      ),
    );
  }
}

/// Compact skeleton for grid/tile layouts (e.g. Home feature tiles).
class NestGridSkeleton extends StatelessWidget {
  const NestGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(
              width: (MediaQuery.of(context).size.width - 42) / 2,
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(
                      width: 28,
                      height: 28,
                      borderRadius: 14,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: 60.0 + (i % 3) * 20,
                      height: 12,
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
