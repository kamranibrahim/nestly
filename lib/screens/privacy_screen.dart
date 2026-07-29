import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// In-app privacy summary for store closed testing / review.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: const [
          NestCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nestly keeps household data private by default.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'What we store',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Account email, nest membership, tasks, lists, calendar, '
                  'expenses, bills, emergency notes, vault file metadata, and '
                  'family timeline events. Vault files upload to Firebase Storage '
                  'under your nest when you are online.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'How it syncs',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nestly is offline-first. Data lives on your device in SQLite '
                  '(Drift) and syncs to Firebase when signed in and connected. '
                  'Only nest members can read or write nest data.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'We may register a push token for reminders (for example bills). '
                  'You can revoke notification permission in system settings.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Questions: privacy@nestly.app (placeholder for store listing).',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
