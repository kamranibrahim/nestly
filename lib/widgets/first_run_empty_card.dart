import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'common.dart';

/// One-tap first-run coaching card for empty module lists.
class FirstRunEmptyCard extends StatelessWidget {
  const FirstRunEmptyCard({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.add_rounded,
    this.color,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      color: color,
      bordered: color == null,
      onTap: onAction,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: color == null ? 0.0 : 0.55,
                  ),
                  shape: BoxShape.circle,
                  border: color == null
                      ? Border.all(color: AppColors.border)
                      : null,
                ),
                child: Icon(icon, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: color == null
                  ? AppColors.inkMuted
                  : AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(icon, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onDark,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
