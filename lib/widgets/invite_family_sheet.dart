import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/telemetry.dart';
import '../theme/app_colors.dart';
import '../data/invite_code.dart';
import 'common.dart';

export '../data/invite_code.dart' show normalizeInviteCode;

String inviteShareText({required String inviteCode, String? nestName}) {
  final nest = (nestName ?? 'our family nest').trim();
  final label = nest.isEmpty ? 'our family nest' : nest;
  return 'Join $label on Nestly!\n\n'
      'Invite code: $inviteCode\n\n'
      'Open Nestly → Have an invite code? → paste this code.';
}

Future<void> copyInviteCode(
  BuildContext context, {
  required String inviteCode,
  String? nestName,
}) async {
  final code = normalizeInviteCode(inviteCode);
  if (code.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: code));
  await NestlyTelemetry.inviteCopied(method: 'copy');
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invite code $code copied — ready to paste')),
  );
}

Future<void> shareInviteCode({
  required String inviteCode,
  String? nestName,
}) async {
  final code = normalizeInviteCode(inviteCode);
  if (code.isEmpty) return;
  await NestlyTelemetry.inviteCopied(method: 'share');
  await SharePlus.instance.share(
    ShareParams(
      text: inviteShareText(inviteCode: code, nestName: nestName),
      subject: 'Join my Nestly nest',
    ),
  );
}

/// Post-create / Nest hub invite sheet: big code, copy, system share.
Future<void> showInviteFamilySheet(
  BuildContext context, {
  required String inviteCode,
  String? nestName,
  bool isPostCreate = false,
}) {
  final code = normalizeInviteCode(inviteCode);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isPostCreate ? 'Nest ready — invite family' : 'Invite family',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPostCreate
                  ? 'Share this code so someone can join in under a minute.'
                  : 'Anyone with Nestly can join using this 6-character code.',
              style: const TextStyle(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            NestCard(
              color: AppColors.surfaceMuted,
              bordered: false,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Column(
                children: [
                  const Text(
                    'Invite code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                await shareInviteCode(inviteCode: code, nestName: nestName);
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share invite'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await copyInviteCode(
                  sheetContext,
                  inviteCode: code,
                  nestName: nestName,
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy code'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (isPostCreate) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Skip for now'),
              ),
            ],
          ],
        ),
      );
    },
  );
}
