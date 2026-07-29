import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/repositories.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.simpleCurrency();
    final expensesAsync = ref.watch(expensesProvider);
    final spent = ref.watch(monthSpendProvider).valueOrNull ?? 0;
    final billsAsync = ref.watch(billsProvider);
    final progress =
        (spent / ExpenseRepository.monthBudget).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
        children: [
          NestCard(
            color: AppColors.primary,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This month',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(spent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'of ${currency.format(ExpenseRepository.monthBudget)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const SectionLabel('Recent'),
          expensesAsync.when(
            loading: () => const NestLoadingSkeleton(itemCount: 2),
            error: (e, _) => NestCard(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return const NestCard(
                  child: Text(
                    'No expenses yet. Tap + to add one.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                );
              }
              return NestCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          items[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${items[i].category}'
                          '${items[i].paidBy.isEmpty ? '' : ' · ${items[i].paidBy}'}',
                        ),
                        trailing: Text(
                          currency.format(items[i].amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (i != items.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: SectionLabel('Bills')),
              TextButton(
                onPressed: () => _addBill(context, ref),
                child: const Text('Add bill'),
              ),
            ],
          ),
          billsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('$e'),
            data: (bills) {
              if (bills.isEmpty) {
                return const NestCard(
                  child: Text(
                    'No bills tracked yet.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                );
              }
              return NestCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < bills.length; i++) ...[
                      ListTile(
                        onTap: () async {
                          await ref
                              .read(billRepositoryProvider)
                              .togglePaid(bills[i]);
                          await ref
                              .read(notificationServiceProvider)
                              .rescheduleBillReminders();
                          try {
                            await ref.read(syncServiceProvider).syncAll();
                          } catch (_) {}
                        },
                        leading: Icon(
                          bills[i].paid
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          color: bills[i].paid
                              ? AppColors.tileGreen
                              : AppColors.tileOrange,
                        ),
                        title: Text(
                          bills[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_dueLabel(bills[i])),
                        trailing: Text(
                          currency.format(bills[i].amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (i != bills.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _dueLabel(Bill bill) {
    if (bill.paid) return 'Paid';
    final days = bill.dueAt
        .difference(DateTime.now())
        .inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  Future<void> _addExpense(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String title, double amount})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            return sheetBody(
              context: context,
              children: [
                sheetHandle(),
                const SizedBox(height: 6),
                const Text(
                  'Add expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c[0],
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: c[1],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(c[1].text.trim());
                    final name = c[0].text.trim();
                    if (name.isEmpty || parsed == null) {
                      Navigator.pop(context);
                      return;
                    }
                    Navigator.pop(context, (title: name, amount: parsed));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      await ref.read(expenseRepositoryProvider).addExpense(
            title: result.title,
            amount: result.amount,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }

  Future<void> _addBill(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String title, double amount})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            return sheetBody(
              context: context,
              children: [
                sheetHandle(),
                const SizedBox(height: 6),
                const Text(
                  'Add bill',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c[0],
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: c[1],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(c[1].text.trim());
                    final name = c[0].text.trim();
                    if (name.isEmpty || parsed == null) {
                      Navigator.pop(context);
                      return;
                    }
                    Navigator.pop(context, (title: name, amount: parsed));
                  },
                  child: const Text('Save · due in 7 days'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      await ref.read(billRepositoryProvider).addBill(
            title: result.title,
            amount: result.amount,
            dueAt: DateTime.now().add(const Duration(days: 7)),
          );
      await ref.read(notificationServiceProvider).rescheduleBillReminders();
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}
