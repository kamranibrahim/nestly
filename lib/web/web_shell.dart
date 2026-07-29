import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import 'web_app.dart';

class WebShell extends ConsumerStatefulWidget {
  const WebShell({
    super.key,
    required this.nestId,
    required this.nestName,
  });

  final String nestId;
  final String nestName;

  @override
  ConsumerState<WebShell> createState() => _WebShellState();
}

class _WebShellState extends ConsumerState<WebShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      _CalendarPane(nestId: widget.nestId),
      _TasksPane(nestId: widget.nestId),
      _ShoppingPane(nestId: widget.nestId),
    ];

    final content = ColoredBox(
      color: AppColors.background,
      child: pages[_index],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surface,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                child: Column(
                  children: [
                    const Text(
                      'nestly',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.nestName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Sign out',
                      onPressed: () =>
                          ref.read(companionStoreProvider).signOut(),
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: Text('Calendar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist_rounded),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag_rounded),
                  label: Text('Lists'),
                ),
              ],
            ),
          Expanded(
            child: Column(
              children: [
                if (!wide)
                  Material(
                    color: AppColors.surface,
                    elevation: 1,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'nestly',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.nestName,
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  ref.read(companionStoreProvider).signOut(),
                              icon: const Icon(Icons.logout_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(child: content),
                if (!wide)
                  NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        label: 'Calendar',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.checklist_outlined),
                        label: 'Tasks',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.shopping_bag_outlined),
                        label: 'Lists',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPane extends ConsumerWidget {
  const _CalendarPane({required this.nestId});

  final String nestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(companionStoreProvider);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: store.watchEvents(nestId),
      builder: (context, snap) {
        final events = snap.data ?? const [];
        final now = DateTime.now();
        final upcoming = events.where((e) {
          final starts = (e['startsAt'] as Timestamp?)?.toDate();
          if (starts == null) return false;
          return !starts.isBefore(DateTime(now.year, now.month, now.day));
        }).toList();

        return _PaneScaffold(
          title: 'Calendar',
          subtitle: 'Upcoming from your shared nest',
          child: snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : upcoming.isEmpty
                  ? const _Empty('No upcoming events. Add them on mobile.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      itemCount: upcoming.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final e = upcoming[i];
                        final starts =
                            (e['startsAt'] as Timestamp?)?.toDate() ?? now;
                        final allDay = e['allDay'] == true;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                '${starts.day}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              e['title'] as String? ?? 'Event',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                DateFormat.MMMd().format(starts),
                                allDay
                                    ? 'All day'
                                    : DateFormat.jm().format(starts),
                                if ((e['location'] as String?)?.isNotEmpty ??
                                    false)
                                  e['location'],
                              ].join(' · '),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _TasksPane extends ConsumerStatefulWidget {
  const _TasksPane({required this.nestId});

  final String nestId;

  @override
  ConsumerState<_TasksPane> createState() => _TasksPaneState();
}

class _TasksPaneState extends ConsumerState<_TasksPane> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(companionStoreProvider);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: store.watchTasks(widget.nestId),
      builder: (context, snap) {
        final tasks = snap.data ?? const [];
        return _PaneScaffold(
          title: 'Tasks',
          subtitle: 'Check things off from your laptop',
          trailing: SizedBox(
            width: 320,
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add a task',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () async {
                    final title = _controller.text.trim();
                    if (title.isEmpty) return;
                    await store.addTask(widget.nestId, title);
                    _controller.clear();
                  },
                ),
              ),
              onSubmitted: (_) async {
                final title = _controller.text.trim();
                if (title.isEmpty) return;
                await store.addTask(widget.nestId, title);
                _controller.clear();
              },
            ),
          ),
          child: snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? const _Empty('No tasks yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final t = tasks[i];
                        final done = t['done'] == true;
                        return CheckboxListTile(
                          value: done,
                          onChanged: (_) => store.toggleTask(
                            widget.nestId,
                            t['id'] as String,
                            done,
                          ),
                          title: Text(
                            t['title'] as String? ?? '',
                            style: TextStyle(
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              color: done ? AppColors.inkMuted : AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(t['dueLabel'] as String? ?? ''),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _ShoppingPane extends ConsumerStatefulWidget {
  const _ShoppingPane({required this.nestId});

  final String nestId;

  @override
  ConsumerState<_ShoppingPane> createState() => _ShoppingPaneState();
}

class _ShoppingPaneState extends ConsumerState<_ShoppingPane> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(companionStoreProvider);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: store.watchShopping(widget.nestId),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        return _PaneScaffold(
          title: 'Shopping',
          subtitle: 'Shared grocery list',
          trailing: SizedBox(
            width: 320,
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add an item',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () async {
                    final name = _controller.text.trim();
                    if (name.isEmpty) return;
                    await store.addShoppingItem(widget.nestId, name);
                    _controller.clear();
                  },
                ),
              ),
              onSubmitted: (_) async {
                final name = _controller.text.trim();
                if (name.isEmpty) return;
                await store.addShoppingItem(widget.nestId, name);
                _controller.clear();
              },
            ),
          ),
          child: snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const _Empty('List is empty.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final done = item['done'] == true;
                        return CheckboxListTile(
                          value: done,
                          onChanged: (_) => store.toggleShopping(
                            widget.nestId,
                            item['id'] as String,
                            done,
                          ),
                          title: Text(
                            item['name'] as String? ?? '',
                            style: TextStyle(
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              color: done ? AppColors.inkMuted : AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(item['category'] as String? ?? ''),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _PaneScaffold extends StatelessWidget {
  const _PaneScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 15),
      ),
    );
  }
}
