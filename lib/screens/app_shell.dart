import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/telemetry.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'scan_document_flow.dart';
import 'shopping_screen.dart';
import 'tasks_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    NestlyTelemetry.homeOpen();
  }

  void _go(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(calendarFocusProvider, (prev, next) {
      if (next != null) _go(1);
    });

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
      body: AnimatedTabBody(
        index: _index,
        children: pages,
      ),
      floatingActionButton: Appear(
        duration: AppMotion.slow,
        offset: const Offset(0, 0.2),
        curve: AppMotion.springy,
        child: CircleIconButton(
          icon: Icons.add_rounded,
          size: 46,
          semanticLabel: 'Add to Nestly',
          onTap: () => _showAddSheet(context),
        ),
      ),
      floatingActionButtonLocation: const _FabAboveNav(),
      bottomNavigationBar: Appear(
        delay: AppMotion.fast,
        duration: AppMotion.slow,
        offset: const Offset(0, 0.35),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(10, 0, 10, 4),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navBar,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Semantics(
              container: true,
              label: 'Main navigation',
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
                label: 'Nest',
                selected: _index == 4,
                onTap: () => _go(4),
              ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext shellContext) {
    showModalBottomSheet<void>(
      context: shellContext,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
          child: Stagger(
            step: const Duration(milliseconds: 35),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
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
                  Navigator.pop(sheetContext);
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
                  Navigator.pop(sheetContext);
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
                  Navigator.pop(sheetContext);
                  _go(3);
                  ref.read(pendingAddProvider.notifier).state =
                      PendingAdd.shopping;
                },
              ),
              _AddOption(
                icon: Icons.document_scanner_rounded,
                color: AppColors.tilePink,
                label: 'Scan receipt / invite',
                onTap: () {
                  Navigator.pop(sheetContext);
                  // Sheet context is disposed after pop — use the shell.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    startDocumentScanFlow(shellContext, ref);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FabAboveNav extends StandardFabLocation with FabEndOffsetX {
  const _FabAboveNav();

  @override
  double getOffsetY(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
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
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        selected: selected,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.navPill : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.ink : const Color(0xFF9A9A9E),
                ),
              ),
            ),
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
        semanticLabel: label,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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
