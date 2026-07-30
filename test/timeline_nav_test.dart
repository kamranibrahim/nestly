import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/timeline_nav.dart';

void main() {
  test('classifies common timeline messages', () {
    expect(
      classifyTimelineMessage('Completed "Walk dog"'),
      TimelineModule.tasks,
    );
    expect(
      classifyTimelineMessage('Checked off milk'),
      TimelineModule.shopping,
    );
    expect(
      classifyTimelineMessage('Completed care: Feed cat'),
      TimelineModule.care,
    );
    expect(
      classifyTimelineMessage('Added 3 ingredients for Tacos'),
      TimelineModule.meals,
    );
    expect(
      classifyTimelineMessage('Sara added insurance to the vault'),
      TimelineModule.vault,
    );
    expect(
      classifyTimelineMessage('Added pickup task for Soccer'),
      TimelineModule.school,
    );
    expect(
      classifyTimelineMessage('Done: Soccer practice'),
      TimelineModule.school,
    );
  });
}
