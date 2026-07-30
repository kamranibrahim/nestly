import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/nest_a11y.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';

/// Warm cream / peach onboarding palette (matches launch reference).
abstract final class OnboardColors {
  static const Color cream = Color(0xFFFBF6F0);
  static const Color peach = Color(0xFFF3C7A8);
  static const Color peachDeep = Color(0xFFE8A882);
  static const Color cocoa = Color(0xFF3A2A22);
  static const Color cocoaMuted = Color(0xFFB7A79A);
  static const Color inkSoft = Color(0xFF5C534C);
  static const Color sparkTeal = Color(0xFF9BCFC4);
  static const Color tagToday = Color(0xFFF3C7A8);
  static const Color tagTomorrow = Color(0xFFD4E7B3);
}

class OnboardHeroOrganize extends StatefulWidget {
  const OnboardHeroOrganize({super.key});

  @override
  State<OnboardHeroOrganize> createState() => _OnboardHeroOrganizeState();
}

class _OnboardHeroOrganizeState extends State<OnboardHeroOrganize>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NestA11y.reduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = NestA11y.reduceMotion(context)
            ? 0.0
            : Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(scale: 1 + t * 0.02, child: child);
      },
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    OnboardColors.peach.withValues(alpha: 0.55),
                    OnboardColors.peach.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CustomPaint(
              size: const Size(280, 280),
              painter: _DashedOrbitPainter(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const _OrbitAvatar(
              alignment: Alignment(-0.78, -0.55),
              initials: 'S',
              color: AppColors.tilePink,
              size: 58,
            ),
            const _OrbitAvatar(
              alignment: Alignment(0.82, -0.42),
              initials: 'K',
              color: AppColors.accent,
              size: 52,
            ),
            const _OrbitAvatar(
              alignment: Alignment(-0.88, 0.35),
              initials: 'A',
              color: AppColors.mint,
              size: 48,
            ),
            const _OrbitAvatar(
              alignment: Alignment(0.78, 0.48),
              initials: 'M',
              color: AppColors.tileOrange,
              size: 54,
            ),
            const _OrbitAvatar(
              alignment: Alignment(0.05, -0.92),
              initials: 'N',
              color: AppColors.tileTeal,
              size: 44,
            ),
            const _FloatIcon(
              alignment: Alignment(-0.55, -0.05),
              icon: Icons.calendar_month_rounded,
            ),
            const _FloatIcon(
              alignment: Alignment(0.58, 0.05),
              icon: Icons.shopping_basket_rounded,
            ),
            const _FloatIcon(
              alignment: Alignment(0.12, 0.72),
              icon: Icons.chat_bubble_rounded,
            ),
            const _Sparkle(alignment: Alignment(-0.2, -0.7), color: OnboardColors.peachDeep),
            const _Sparkle(alignment: Alignment(0.35, -0.55), color: OnboardColors.sparkTeal, size: 14),
            const _Sparkle(alignment: Alignment(-0.4, 0.65), color: OnboardColors.sparkTeal, size: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: OnboardColors.cocoa.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: OnboardColors.cocoa, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Family, Simplified',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: OnboardColors.cocoa,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardHeroAi extends StatelessWidget {
  const OnboardHeroAi({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            left: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: OnboardColors.cocoa.withValues(alpha: 0.1),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _MockEvent(
                    title: 'School PTA Meeting',
                    meta: '5:00 PM · MIT School',
                    tag: 'Today',
                    tagColor: OnboardColors.tagToday,
                  ),
                  SizedBox(height: 8),
                  _MockEvent(
                    title: 'Doctor Appointment',
                    meta: '11:30 AM · Apollo',
                    tag: 'Tomorrow',
                    tagColor: OnboardColors.tagTomorrow,
                  ),
                  SizedBox(height: 8),
                  _MockTask(title: 'Call internet provider'),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OrbitAvatar(initials: 'S', color: AppColors.tilePink, size: 46),
                SizedBox(width: 10),
                _OrbitAvatar(initials: 'K', color: AppColors.accent, size: 52),
                SizedBox(width: 10),
                _OrbitAvatar(initials: 'A', color: AppColors.mint, size: 44),
                SizedBox(width: 10),
                _OrbitAvatar(initials: 'M', color: AppColors.tileOrange, size: 48),
              ],
            ),
          ),
          const _Sparkle(alignment: Alignment(-0.78, 0.55), color: OnboardColors.peachDeep),
          const _Sparkle(alignment: Alignment(0.82, 0.48), color: OnboardColors.sparkTeal, size: 16),
          const _Sparkle(alignment: Alignment(0.7, -0.55), color: OnboardColors.peach, size: 12),
        ],
      ),
    );
  }
}

class OnboardHeroConnect extends StatefulWidget {
  const OnboardHeroConnect({super.key});

  @override
  State<OnboardHeroConnect> createState() => _OnboardHeroConnectState();
}

class _OnboardHeroConnectState extends State<OnboardHeroConnect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NestA11y.reduceMotion(context)) {
      _drift.stop();
      _drift.value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_drift.value);
        return SizedBox(
          height: 320,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, -8 + t * 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CapsulePortrait(
                      initials: 'S',
                      color: AppColors.tilePink,
                      height: 168,
                      offsetY: 24,
                    ),
                    SizedBox(width: 10),
                    _CapsulePortrait(
                      initials: 'K',
                      color: AppColors.accent,
                      height: 200,
                      offsetY: -8,
                    ),
                    SizedBox(width: 10),
                    _CapsulePortrait(
                      initials: 'A',
                      color: AppColors.mint,
                      height: 168,
                      offsetY: 28,
                    ),
                  ],
                ),
              ),
              const _FloatIcon(
                alignment: Alignment(-0.22, -0.08),
                icon: Icons.calendar_month_rounded,
                size: 36,
              ),
              const _FloatIcon(
                alignment: Alignment(0.22, 0.18),
                icon: Icons.shopping_basket_rounded,
                size: 36,
              ),
              const _FloatIcon(
                alignment: Alignment(0.02, 0.55),
                icon: Icons.chat_bubble_rounded,
                size: 34,
              ),
              const _Sparkle(alignment: Alignment(-0.72, -0.35), color: OnboardColors.peachDeep),
              const _Sparkle(alignment: Alignment(0.78, -0.2), color: OnboardColors.sparkTeal, size: 16),
              const _Sparkle(alignment: Alignment(-0.65, 0.55), color: OnboardColors.sparkTeal, size: 12),
            ],
          ),
        );
      },
    );
  }
}

class _CapsulePortrait extends StatelessWidget {
  const _CapsulePortrait({
    required this.initials,
    required this.color,
    required this.height,
    this.offsetY = 0,
  });

  final String initials;
  final Color color;
  final double height;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Container(
        width: 78,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: OnboardColors.cocoa.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: height > 180 ? 34 : 28,
            fontWeight: FontWeight.w800,
            color: OnboardColors.cocoa.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _MockEvent extends StatelessWidget {
  const _MockEvent({
    required this.title,
    required this.meta,
    required this.tag,
    required this.tagColor,
  });

  final String title;
  final String meta;
  final String tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: OnboardColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: OnboardColors.cocoa,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OnboardColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tagColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: OnboardColors.cocoa,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockTask extends StatelessWidget {
  const _MockTask({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: OnboardColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: OnboardColors.cocoaMuted, width: 1.6),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: OnboardColors.cocoa,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitAvatar extends StatelessWidget {
  const _OrbitAvatar({
    this.alignment,
    required this.initials,
    required this.color,
    this.size = 48,
  });

  final Alignment? alignment;
  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: OnboardColors.cocoa.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          color: OnboardColors.cocoa.withValues(alpha: 0.8),
        ),
      ),
    );

    if (alignment == null) return avatar;
    return Align(alignment: alignment!, child: avatar);
  }
}

class _FloatIcon extends StatelessWidget {
  const _FloatIcon({
    required this.alignment,
    required this.icon,
    this.size = 40,
  });

  final Alignment alignment;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: OnboardColors.cocoa,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: OnboardColors.cocoa.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.48),
      ),
    );
  }
}

class _Sparkle extends StatefulWidget {
  const _Sparkle({
    required this.alignment,
    required this.color,
    this.size = 18,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400 + widget.size.toInt() * 40),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NestA11y.reduceMotion(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Transform.rotate(
            angle: t * 0.4,
            child: Opacity(opacity: 0.55 + t * 0.45, child: child),
          );
        },
        child: Icon(
          Icons.auto_awesome_rounded,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}

class _DashedOrbitPainter extends CustomPainter {
  _DashedOrbitPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    const dash = 7.0;
    const gap = 6.0;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    for (var i = 0; i < count; i++) {
      final start = (i * (dash + gap)) / radius;
      final end = start + dash / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Soft entrance for page body when the page index changes.
class OnboardFadeSlide extends StatelessWidget {
  const OnboardFadeSlide({
    super.key,
    required this.child,
    required this.pageKey,
  });

  final Widget child;
  final Object pageKey;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(pageKey),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
