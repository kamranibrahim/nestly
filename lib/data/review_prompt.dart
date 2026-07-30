import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'db/app_database.dart';

const reviewPromptShownMetaKey = 'reviewPromptShown';

/// Pure gate used by [maybeRequestStoreReview] (and unit tests).
bool isStoreReviewEligible({
  required int memberCount,
  DateTime? nestCreatedAt,
  required bool alreadyShown,
  DateTime? now,
}) {
  if (memberCount < 2) return false;
  if (alreadyShown) return false;
  if (nestCreatedAt == null) return false;
  final n = now ?? DateTime.now();
  return n.difference(nestCreatedAt) >= const Duration(days: 3);
}

/// Asks for an App Store / Play review once the nest has 2+ members and is ≥3 days old.
Future<void> maybeRequestStoreReview(
  AppDatabase db, {
  required int memberCount,
  DateTime? nestCreatedAt,
  DateTime? now,
}) async {
  if (kIsWeb) return;

  final alreadyShown = await db.getMeta(reviewPromptShownMetaKey) == '1';
  if (!isStoreReviewEligible(
    memberCount: memberCount,
    nestCreatedAt: nestCreatedAt,
    alreadyShown: alreadyShown,
    now: now,
  )) {
    return;
  }

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
