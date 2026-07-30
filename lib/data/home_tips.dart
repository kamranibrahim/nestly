import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'telemetry.dart';

const tipInvitePartnerMetaKey = 'tipInvitePartnerDismissed';
const tipInviteSoloBannerMetaKey = 'tipInviteSoloBannerDismissed';
const firstSharedCheckoffMetaKey = 'firstSharedCheckoffLogged';

final inviteTipDismissedProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getMeta(tipInvitePartnerMetaKey) == '1';
});

final inviteSoloBannerDismissedProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getMeta(tipInviteSoloBannerMetaKey) == '1';
});

Future<void> dismissInvitePartnerTip(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await db.setMeta(tipInvitePartnerMetaKey, '1');
  ref.invalidate(inviteTipDismissedProvider);
}

Future<void> dismissInviteSoloBanner(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await db.setMeta(tipInviteSoloBannerMetaKey, '1');
  ref.invalidate(inviteSoloBannerDismissedProvider);
}

/// True when the nest has been alone for at least 24 hours.
bool nestAlonePastDay(DateTime? nestCreatedAt, {DateTime? now}) {
  if (nestCreatedAt == null) return false;
  final n = now ?? DateTime.now();
  return n.difference(nestCreatedAt) >= const Duration(hours: 24);
}

/// Logs [first_shared_checkoff] once when the nest already has 2+ members.
Future<void> maybeLogFirstSharedCheckoff(
  AppDatabase db, {
  required String kind,
}) async {
  if (await db.getMeta(firstSharedCheckoffMetaKey) == '1') return;
  final members = await db.select(db.nestMembers).get();
  if (members.length < 2) return;
  await db.setMeta(firstSharedCheckoffMetaKey, '1');
  await NestlyTelemetry.firstSharedCheckoff(kind: kind);
}
