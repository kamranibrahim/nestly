import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';

const tipInvitePartnerMetaKey = 'tipInvitePartnerDismissed';

final inviteTipDismissedProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getMeta(tipInvitePartnerMetaKey) == '1';
});

Future<void> dismissInvitePartnerTip(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await db.setMeta(tipInvitePartnerMetaKey, '1');
  ref.invalidate(inviteTipDismissedProvider);
}
