import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import 'nest_a11y.dart';

/// Scale-down press feedback for tappable surfaces.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.borderRadius,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || widget.onTap == null) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = NestA11y.reduceMotion(context);
    final core = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: (!reduce && _pressed) ? AppMotion.pressScale : 1,
        duration: reduce ? Duration.zero : AppMotion.instant,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );

    if (widget.onTap == null && widget.semanticLabel == null) return core;

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.enabled && widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onTap : null,
      child: core,
    );
  }
}

/// One-shot fade + slide entrance. Replays only when [replayKey] changes.
class Appear extends StatefulWidget {
  const Appear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.medium,
    this.offset = AppMotion.enterOffset,
    this.curve = AppMotion.standard,
    this.replayKey,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final Object? replayKey;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Object? _lastKey;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _lastKey = widget.replayKey;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NestA11y.reduceMotion(context)) {
      _delayTimer?.cancel();
      _controller.value = 1;
      _started = true;
      return;
    }
    if (!_started) {
      _started = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant Appear oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replayKey != null && widget.replayKey != _lastKey) {
      _lastKey = widget.replayKey;
      if (NestA11y.reduceMotion(context)) {
        _controller.value = 1;
        return;
      }
      _controller.reset();
      _play();
    }
  }

  void _play() {
    _delayTimer?.cancel();
    if (widget.delay > Duration.zero) {
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (NestA11y.reduceMotion(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Staggers [Appear] across a list of children.
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.children,
    this.step = AppMotion.stagger,
    this.duration = AppMotion.medium,
    this.offset = AppMotion.enterOffset,
    this.replayKey,
  });

  final List<Widget> children;
  final Duration step;
  final Duration duration;
  final Offset offset;
  final Object? replayKey;

  @override
  Widget build(BuildContext context) {
    if (NestA11y.reduceMotion(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Appear(
            delay: step * i,
            duration: duration,
            offset: offset,
            replayKey: replayKey == null ? null : '$replayKey-$i',
            child: children[i],
          ),
      ],
    );
  }
}

/// Keeps tab state while fading/sliding the active tab.
class AnimatedTabBody extends StatelessWidget {
  const AnimatedTabBody({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (NestA11y.reduceMotion(context)) {
      return IndexedStack(index: index, children: children);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: _TabPane(
              active: i == index,
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class _TabPane extends StatelessWidget {
  const _TabPane({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: AppMotion.medium,
      curve: AppMotion.soft,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.012),
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        child: child,
      ),
    );
  }
}

/// Soft fade + slight rise for pushed routes.
class NestPageTransitionsBuilder extends PageTransitionsBuilder {
  const NestPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (NestA11y.reduceMotion(context)) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.soft,
    );
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.soft,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.02, 0),
          ).animate(secondary),
          child: child,
        ),
      ),
    );
  }
}

Future<T?> nestPush<T extends Object?>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(builder: (_) => page),
  );
}
