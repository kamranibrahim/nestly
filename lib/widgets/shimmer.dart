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

/// Shared shimmer clock so every bone sweeps in sync.
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1600),
  });

  final Widget child;
  final Duration duration;

  static Animation<double>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerInherited>()
        ?.animation;
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerInherited(
      animation: _controller,
      child: widget.child,
    );
  }
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerInherited oldWidget) =>
      animation != oldWidget.animation;
}

/// Soft diagonal highlight bone — prefers [ShimmerScope] when present.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 10,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _local;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shared = ShimmerScope.of(context);
    if (shared != null) {
      _animation = shared;
      return;
    }
    _local ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _animation = _local;
  }

  @override
  void dispose() {
    _local?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    if (animation == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + 2.8 * t, -0.35),
              end: Alignment(-0.2 + 2.8 * t, 0.35),
              colors: const [
                Color(0xFFE8E8EC),
                Color(0xFFF4F4F6),
                Color(0xFFFAFAFB),
                Color(0xFFF4F4F6),
                Color(0xFFE8E8EC),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
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
    return ShimmerScope(
      child: Padding(
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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
    return ShimmerScope(
      child: Padding(
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
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
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
      ),
    );
  }
}

/// Full-page home placeholder — mirrors greeting, hero, snapshot, tiles.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tileW = (width - 28) / 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ShimmerScope(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
            children: [
              const Row(
                children: [
                  Expanded(
                    child: ShimmerBox(height: 28, borderRadius: 10),
                  ),
                  SizedBox(width: 10),
                  ShimmerBox(width: 38, height: 38, borderRadius: 999),
                  SizedBox(width: 8),
                  ShimmerBox(width: 38, height: 38, borderRadius: 999),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  ShimmerBox(width: 88, height: 30, borderRadius: 999),
                  SizedBox(width: 8),
                  ShimmerBox(width: 108, height: 30, borderRadius: 999),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 210, height: 18, borderRadius: 8),
                    SizedBox(height: 12),
                    ShimmerBox(height: 12, borderRadius: 8),
                    SizedBox(height: 8),
                    ShimmerBox(width: 160, height: 12, borderRadius: 8),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ShimmerBox(height: 40, borderRadius: 14),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ShimmerBox(height: 40, borderRadius: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ShimmerBox(width: 120, height: 14, borderRadius: 6),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 4; i++)
                    SizedBox(
                      width: tileW,
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            ShimmerBox(
                              width: 28,
                              height: 28,
                              borderRadius: 10,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ShimmerBox(height: 10, borderRadius: 6),
                                  SizedBox(height: 6),
                                  ShimmerBox(
                                    width: 54,
                                    height: 10,
                                    borderRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const ShimmerBox(width: 140, height: 14, borderRadius: 6),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: const Column(
                  children: [
                    _HomeNeedBone(),
                    SizedBox(height: 12),
                    _HomeNeedBone(short: true),
                    SizedBox(height: 12),
                    _HomeNeedBone(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ShimmerBox(width: 96, height: 14, borderRadius: 6),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 6; i++)
                    SizedBox(
                      width: tileW,
                      child: Container(
                        height: 88,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? AppColors.accent.withValues(alpha: 0.28)
                              : AppColors.mint.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: 30,
                              height: 30,
                              borderRadius: 12,
                            ),
                            Spacer(),
                            ShimmerBox(width: 72, height: 12, borderRadius: 6),
                            SizedBox(height: 6),
                            ShimmerBox(width: 48, height: 10, borderRadius: 6),
                          ],
                        ),
                      ),
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

class _HomeNeedBone extends StatelessWidget {
  const _HomeNeedBone({this.short = false});

  final bool short;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerBox(width: 36, height: 36, borderRadius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: short ? 120 : double.infinity,
                height: 12,
                borderRadius: 6,
              ),
              const SizedBox(height: 8),
              const ShimmerBox(width: 90, height: 10, borderRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const ShimmerBox(width: 56, height: 28, borderRadius: 999),
      ],
    );
  }
}
