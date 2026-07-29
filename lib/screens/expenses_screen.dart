import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../data/repositories.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';
import '../widgets/shimmer.dart';

const _expenseCategories = [
  'Groceries',
  'Transport',
  'Kids',
  'Home',
  'Dining',
  'Health',
  'General',
];

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
        onPressed: () => showExpenseSheet(context, ref),
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
                        onTap: () =>
                            showExpenseSheet(context, ref, existing: items[i]),
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
                onPressed: () => showBillSheet(context, ref),
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
                        onTap: () =>
                            showBillSheet(context, ref, existing: bills[i]),
                        leading: IconButton(
                          tooltip: bills[i].paid ? 'Mark unpaid' : 'Mark paid',
                          onPressed: () async {
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
                          icon: Icon(
                            bills[i].paid
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            color: bills[i].paid
                                ? AppColors.tileGreen
                                : AppColors.tileOrange,
                          ),
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

  static String _dueLabel(Bill bill) {
    if (bill.paid) return 'Paid';
    final days = bill.dueAt.difference(DateTime.now()).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days · ${DateFormat.MMMd().format(bill.dueAt)}';
  }

  static Future<void> showExpenseSheet(
    BuildContext context,
    WidgetRef ref, {
    Expense? existing,
  }) async {
    final members = List<NestMember>.from(
      ref.read(membersProvider).valueOrNull ?? const [],
    )..sort((a, b) => MemberRoles.adultLikeFirst(a.role, b.role));

    final result = await showModalBottomSheet<
        ({
          String title,
          double amount,
          String category,
          String paidBy,
          bool deleteExpense,
        })>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExpenseSheet(
        existing: existing,
        members: members,
      ),
    );

    if (result == null) return;

    if (result.deleteExpense && existing != null) {
      await ref.read(expenseRepositoryProvider).deleteExpense(existing.id);
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
      return;
    }

    if (result.title.isEmpty) return;

    if (existing == null) {
      await ref.read(expenseRepositoryProvider).addExpense(
            title: result.title,
            amount: result.amount,
            category: result.category,
            paidBy: result.paidBy,
          );
    } else {
      await ref.read(expenseRepositoryProvider).updateExpense(
            id: existing.id,
            title: result.title,
            amount: result.amount,
            category: result.category,
            paidBy: result.paidBy,
          );
    }
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
  }

  static Future<void> showBillSheet(
    BuildContext context,
    WidgetRef ref, {
    Bill? existing,
  }) async {
    final result = await showModalBottomSheet<
        ({
          String title,
          double amount,
          DateTime dueAt,
          bool deleteBill,
        })>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BillSheet(existing: existing),
    );

    if (result == null) return;

    if (result.deleteBill && existing != null) {
      await ref.read(billRepositoryProvider).deleteBill(existing.id);
      await ref.read(notificationServiceProvider).rescheduleBillReminders();
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
      return;
    }

    if (result.title.isEmpty) return;

    if (existing == null) {
      await ref.read(billRepositoryProvider).addBill(
            title: result.title,
            amount: result.amount,
            dueAt: result.dueAt,
          );
    } else {
      await ref.read(billRepositoryProvider).updateBill(
            id: existing.id,
            title: result.title,
            amount: result.amount,
            dueAt: result.dueAt,
          );
    }
    await ref.read(notificationServiceProvider).rescheduleBillReminders();
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
  }
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({
    required this.members,
    this.existing,
  });

  final List<NestMember> members;
  final Expense? existing;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late String _category;
  late String _paidBy;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _amount = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(
            existing.amount == existing.amount.roundToDouble() ? 0 : 2,
          ),
    );
    _category = existing?.category ?? 'General';
    _paidBy = existing?.paidBy ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit({bool deleteExpense = false}) {
    final name = _title.text.trim();
    final parsed = double.tryParse(_amount.text.trim());
    if (!deleteExpense && (name.isEmpty || parsed == null)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      (
        title: name,
        amount: parsed ?? 0,
        category: _category,
        paidBy: _paidBy,
        deleteExpense: deleteExpense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final cats = {
      ..._expenseCategories,
      if (!_expenseCategories.contains(_category)) _category,
    }.toList();

    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 6),
        Text(
          existing == null ? 'Add expense' : 'Edit expense',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          autofocus: existing == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final cat in cats)
              SoftPill(
                label: cat,
                selected: _category == cat,
                onTap: () => setState(() => _category = cat),
              ),
          ],
        ),
        if (widget.members.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Paid by',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              SoftPill(
                label: 'Anyone',
                selected: _paidBy.isEmpty,
                onTap: () => setState(() => _paidBy = ''),
              ),
              for (final m in widget.members)
                SoftPill(
                  label: m.name.split(' ').first,
                  selected: _paidBy == m.name,
                  onTap: () => setState(() => _paidBy = m.name),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _submit,
          child: Text(existing == null ? 'Save' : 'Save changes'),
        ),
        if (existing != null)
          TextButton(
            onPressed: () => _submit(deleteExpense: true),
            child: const Text(
              'Delete expense',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

class _BillSheet extends StatefulWidget {
  const _BillSheet({this.existing});

  final Bill? existing;

  @override
  State<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends State<_BillSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late DateTime _dueAt;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _amount = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(
            existing.amount == existing.amount.roundToDouble() ? 0 : 2,
          ),
    );
    final now = DateTime.now();
    _dueAt = existing?.dueAt ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit({bool deleteBill = false}) {
    final name = _title.text.trim();
    final parsed = double.tryParse(_amount.text.trim());
    if (!deleteBill && (name.isEmpty || parsed == null)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      (
        title: name,
        amount: parsed ?? 0,
        dueAt: _dueAt,
        deleteBill: deleteBill,
      ),
    );
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _dueAt = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 6),
        Text(
          existing == null ? 'Add bill' : 'Edit bill',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          autofocus: existing == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 10),
        SoftPill(
          label: 'Due · ${DateFormat('EEE, MMM d').format(_dueAt)}',
          selected: true,
          onTap: _pickDue,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final days in const [3, 7, 14, 30])
              SoftPill(
                label: 'In $days days',
                onTap: () {
                  final now = DateTime.now();
                  setState(() {
                    _dueAt = DateTime(now.year, now.month, now.day)
                        .add(Duration(days: days));
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _submit,
          child: Text(existing == null ? 'Save' : 'Save changes'),
        ),
        if (existing != null)
          TextButton(
            onPressed: () => _submit(deleteBill: true),
            child: const Text(
              'Delete bill',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}
