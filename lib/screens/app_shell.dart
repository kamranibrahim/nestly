import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'shopping_screen.dart';
import 'tasks_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _go),
      const CalendarScreen(),
      const TasksScreen(),
      const ShoppingScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _Tab(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _index == 0,
                onTap: () => _go(0),
              ),
              _Tab(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                selected: _index == 1,
                onTap: () => _go(1),
              ),
              const SizedBox(width: 56),
              _Tab(
                icon: Icons.checklist_rounded,
                label: 'Tasks',
                selected: _index == 2,
                onTap: () => _go(2),
              ),
              _Tab(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                selected: _index == 4 || _index == 3,
                onTap: () => _go(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add to Nestly',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AddOption(
                  icon: Icons.event_rounded,
                  color: AppColors.tileBlue,
                  label: 'Event',
                  onTap: () {
                    Navigator.pop(context);
                    _go(1);
                    ref.read(pendingAddProvider.notifier).state =
                        PendingAdd.event;
                  },
                ),
                _AddOption(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.tileGreen,
                  label: 'Task',
                  onTap: () {
                    Navigator.pop(context);
                    _go(2);
                    ref.read(pendingAddProvider.notifier).state =
                        PendingAdd.task;
                  },
                ),
                _AddOption(
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.tileOrange,
                  label: 'Shopping item',
                  onTap: () {
                    Navigator.pop(context);
                    _go(3);
                    ref.read(pendingAddProvider.notifier).state =
                        PendingAdd.shopping;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
    );
  }
}
