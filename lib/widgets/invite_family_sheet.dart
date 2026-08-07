import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/telemetry.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_colors.dart';
import '../data/invite_code.dart';
import 'common.dart';

export '../data/invite_code.dart' show normalizeInviteCode;

/// Marketing / download page used in invite shares.
const casaioInviteMarketingUrl = 'https://casaio.app';

String inviteShareText({
  required String inviteCode,
  String? nestName,
  AppLocalizations? l10n,
}) {
  final fallback = l10n?.inviteShareFallbackNest ?? 'our family nest';
  final nest = (nestName ?? fallback).trim();
  final label = nest.isEmpty ? fallback : nest;
  if (l10n != null) {
    return l10n.inviteShareText(label, inviteCode, casaioInviteMarketingUrl);
  }
  return 'Join $label on Casaio!\n\n'
      'Invite code: $inviteCode\n\n'
      'Get the app: $casaioInviteMarketingUrl\n'
      'Then open Casaio → Have an invite code? → paste this code.';
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
    SnackBar(content: Text(context.l10n.inviteCodeCopied(code))),
  );
}

Future<void> shareInviteCode({
  required String inviteCode,
  String? nestName,
  AppLocalizations? l10n,
}) async {
  final code = normalizeInviteCode(inviteCode);
  if (code.isEmpty) return;
  await NestlyTelemetry.inviteCopied(method: 'share');
  await SharePlus.instance.share(
    ShareParams(
      text: inviteShareText(inviteCode: code, nestName: nestName, l10n: l10n),
      subject: l10n?.inviteShareSubject ?? 'Join my Casaio nest',
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
      final l10n = sheetContext.l10n;
      final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isPostCreate ? l10n.inviteNestReady : l10n.inviteFamilyTitle,
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPostCreate ? l10n.inviteNestReadyBody : l10n.inviteSheetBody,
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: l10n.inviteCodeA11y(code),
              readOnly: true,
              child: NestCard(
                color: AppColors.surfaceMuted,
                bordered: false,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      l10n.nestSetupInviteCode,
                      style: Theme.of(sheetContext).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      code,
                      style: Theme.of(sheetContext).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                await shareInviteCode(
                  inviteCode: code,
                  nestName: nestName,
                  l10n: l10n,
                );
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l10n.commonShare),
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
              label: Text(l10n.inviteCopyCode),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (isPostCreate) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(l10n.inviteSkipForNow),
              ),
            ],
          ],
        ),
      );
    },
  );
}
