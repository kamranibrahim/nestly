import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.screenAboutShort)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 36),
        children: [
          NestCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/brand/logos/casaio-logo-mark-plain.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.appName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.aboutTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.aboutVersion('1.0.0'),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NestCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: AppColors.accentDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.screenPrivacyShort,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
