import 'enums.dart';

export 'enums.dart' show TimelineModule;

TimelineModule classifyTimelineMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('completed care:')) return TimelineModule.care;
  if (m.contains('pickup task')) return TimelineModule.school;
  if (m.startsWith('done:')) return TimelineModule.school;
  if (m.contains('checked off')) return TimelineModule.shopping;
  if (m.contains('vault') || m.contains('uploaded')) return TimelineModule.vault;
  if (m.contains('dinner') || m.contains('ingredient')) {
    return TimelineModule.meals;
  }
  if (m.contains('completed "') || m.startsWith('completed ')) {
    return TimelineModule.tasks;
  }
  if (m.contains('grocery') || m.contains('shopping')) {
    return TimelineModule.shopping;
  }
  if (m.contains('bill') || m.contains('paid') || m.contains('expense')) {
    return TimelineModule.other;
  }
  return TimelineModule.other;
}
