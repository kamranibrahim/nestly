import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
        children: [
          NestCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'N',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nestly',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The operating system for modern families',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
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
            child: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: AppColors.accentDeep),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
