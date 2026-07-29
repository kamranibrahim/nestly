import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'motion.dart';

class NestCard extends StatelessWidget {
  const NestCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.onTap,
    this.color,
    this.borderRadius = 18,
    this.bordered = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.surface;
    final needsBorder = bordered && color == null;
    final card = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: needsBorder ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );
  }
}

class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.background,
    this.foreground,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final bg = background ??
        (selected ? AppColors.primary : AppColors.surface);
    final fg = foreground ??
        (selected ? AppColors.onDark : AppColors.ink);
    final pill = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: selected || background != null
            ? null
            : Border.all(color: AppColors.border),
      ),
      child: AnimatedDefaultTextStyle(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        child: Text(label),
      ),
    );

    if (onTap == null) return pill;
    return Pressable(onTap: onTap, child: pill);
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background = AppColors.primary,
    this.foreground = AppColors.onDark,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foreground, size: size * 0.45),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 36,
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      onTap: onTap,
      color: color,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.ink, size: 15),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.ink,
              letterSpacing: -0.2,
              height: 1.1,
            ),
          ),
          if (subtitle != null)...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSecondary,
                height: 1.15,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
