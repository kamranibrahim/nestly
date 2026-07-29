import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: needsBorder ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      ),
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
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
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
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: foreground, size: size * 0.45),
        ),
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
      padding: const EdgeInsets.only(bottom: 6, top: 0),
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
    return Container(
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.ink, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
