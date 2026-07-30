/// Maps timeline copy to a module so Home / Timeline can deep-link.
enum TimelineModule {
  all,
  tasks,
  shopping,
  care,
  meals,
  vault,
  school,
  other,
}

extension TimelineModuleLabel on TimelineModule {
  String get label => switch (this) {
        TimelineModule.all => 'All',
        TimelineModule.tasks => 'Tasks',
        TimelineModule.shopping => 'Lists',
        TimelineModule.care => 'Care',
        TimelineModule.meals => 'Meals',
        TimelineModule.vault => 'Vault',
        TimelineModule.school => 'School',
        TimelineModule.other => 'Other',
      };
}

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
