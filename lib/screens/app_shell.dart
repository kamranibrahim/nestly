import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
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
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      floatingActionButton: CircleIconButton(
        icon: Icons.add_rounded,
        size: 46,
        onTap: () => _showAddSheet(context),
      ),
      floatingActionButtonLocation: const _FabAboveNav(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navBar,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _index == 0,
                onTap: () => _go(0),
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                selected: _index == 1,
                onTap: () => _go(1),
              ),
              _NavItem(
                icon: Icons.checklist_rounded,
                label: 'Tasks',
                selected: _index == 2,
                onTap: () => _go(2),
              ),
              _NavItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Shop',
                selected: _index == 3,
                onTap: () => _go(3),
              ),
              _NavItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                selected: _index == 4,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add to Nestly',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _AddOption(
                  icon: Icons.event_rounded,
                  color: AppColors.accent,
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
                  color: AppColors.mint,
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

/// Sits just above the floating pill nav with a tight 6px gap.
class _FabAboveNav extends StandardFabLocation with FabEndOffsetX {
  const _FabAboveNav();

  @override
  double getOffsetY(ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    return scaffoldGeometry.contentBottom - fabHeight - 6 + adjustment;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 8 : 0,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.navPill : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.ink : const Color(0xFF9A9A9E),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: NestCard(
        onTap: onTap,
        color: color,
        bordered: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.ink, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.north_east_rounded, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
