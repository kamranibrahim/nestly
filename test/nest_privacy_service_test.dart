import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/data/nest_privacy_service.dart';
import 'package:nestly/widgets/invite_family_sheet.dart';

void main() {
  test('nestCloudSubcollections covers synced nest modules', () {
    expect(
      nestCloudSubcollections,
      containsAll([
        'members',
        'tasks',
        'events',
        'vault',
        'locations',
        'school',
      ]),
    );
    expect(nestCloudSubcollections.toSet().length, nestCloudSubcollections.length);
  });

  test('invite share text includes marketing URL and code', () {
    final text = inviteShareText(inviteCode: 'ABC123', nestName: 'Smith Nest');
    expect(text, contains('ABC123'));
    expect(text, contains(nestlyInviteMarketingUrl));
    expect(text, contains('Smith Nest'));
  });
}
