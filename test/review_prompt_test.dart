import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/data/review_prompt.dart';

void main() {
  final created = DateTime(2026, 7, 20);
  final now = DateTime(2026, 7, 30);

  test('requires two members and three days', () {
    expect(
      isStoreReviewEligible(
        memberCount: 1,
        nestCreatedAt: created,
        alreadyShown: false,
        now: now,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        memberCount: 2,
        nestCreatedAt: now.subtract(const Duration(days: 2)),
        alreadyShown: false,
        now: now,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        memberCount: 2,
        nestCreatedAt: created,
        alreadyShown: false,
        now: now,
      ),
      isTrue,
    );
  });

  test('already shown blocks repeat prompts', () {
    expect(
      isStoreReviewEligible(
        memberCount: 3,
        nestCreatedAt: created,
        alreadyShown: true,
        now: now,
      ),
      isFalse,
    );
  });

  test('missing createdAt is not eligible', () {
    expect(
      isStoreReviewEligible(
        memberCount: 2,
        nestCreatedAt: null,
        alreadyShown: false,
        now: now,
      ),
      isFalse,
    );
  });
}
