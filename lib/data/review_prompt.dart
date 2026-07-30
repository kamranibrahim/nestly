import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'db/app_database.dart';

const reviewPromptShownMetaKey = 'reviewPromptShown';

/// Asks for an App Store / Play review once the nest has 2+ members and is ≥3 days old.
Future<void> maybeRequestStoreReview(
  AppDatabase db, {
  required int memberCount,
  DateTime? nestCreatedAt,
  DateTime? now,
}) async {
  if (kIsWeb) return;
  if (memberCount < 2) return;
  if (nestCreatedAt == null) return;

  final n = now ?? DateTime.now();
  if (n.difference(nestCreatedAt) < const Duration(days: 3)) return;

  if (await db.getMeta(reviewPromptShownMetaKey) == '1') return;

  // Persist before showing so we never spam if the OS suppresses the sheet.
  await db.setMeta(reviewPromptShownMetaKey, '1');

  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    }
  } catch (e) {
    debugPrint('Store review skipped: $e');
  }
}
