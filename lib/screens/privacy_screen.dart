import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/nest_privacy_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

final nestPrivacyServiceProvider = Provider<NestPrivacyService>((ref) {
  return NestPrivacyService(ref.watch(databaseProvider));
});

/// In-app privacy summary for store closed testing / review.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await ref.read(nestPrivacyServiceProvider).shareExport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready to share')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This removes you from your nest, deletes your Nestly account, '
          'and clears data on this device. Other family members keep the nest. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(nestPrivacyServiceProvider).deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
        children: [
          const NestCard(
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
                  'Quiet AI (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Document scan sends the photo or PDF you choose to Google’s '
                  'Gemini models through Firebase AI Logic (Vertex AI) so Nestly '
                  'can draft an event, expense, or task. You review before '
                  'anything is saved. Nestly stays free — there is no paywall '
                  'for core family features.',
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
          const SizedBox(height: 10),
          const SectionLabel('Your controls'),
          NestCard(
            onTap: _busy ? null : _export,
            child: Row(
              children: [
                const Icon(Icons.download_rounded, color: AppColors.accentDeep),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Export nest data',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.inkMuted,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          NestCard(
            onTap: _busy ? null : _deleteAccount,
            child: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete account',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
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
