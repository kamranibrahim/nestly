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
import '../data/sync_controller.dart';

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
    final budget = ref.watch(monthBudgetProvider).valueOrNull ??
        ExpenseRepository.defaultMonthBudget;
    final categoryTotals =
        ref.watch(monthCategoryTotalsProvider).valueOrNull ?? const [];
    final billsAsync = ref.watch(billsProvider);
    final safeBudget = budget <= 0 ? ExpenseRepository.defaultMonthBudget : budget;
    final progress = (spent / safeBudget).clamp(0.0, 1.0).toDouble();
    final over = spent > safeBudget;
    final remaining = safeBudget - spent;
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final bills = billsAsync.valueOrNull ?? const <Bill>[];
    final emptyNest = expenses.isEmpty && bills.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          TextButton(
            onPressed: () => showBudgetSheet(context, ref, current: safeBudget),
            child: const Text('Edit'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showExpenseSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 84),
        children: [
          NestCard(
            color: over ? AppColors.danger : AppColors.primary,
            bordered: false,
            onTap: () => showBudgetSheet(context, ref, current: safeBudget),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'This month',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Tap to edit budget',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                  over
                      ? '${currency.format(spent - safeBudget)} over · of ${currency.format(safeBudget)}'
                      : '${currency.format(remaining)} left · of ${currency.format(safeBudget)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
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
          if (categoryTotals.isNotEmpty) ...[
            const SizedBox(height: 6),
            const SectionLabel('By category'),
            NestCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final row in categoryTotals.take(6))
                    SoftPill(
                      label: '${row.category} · ${currency.format(row.total)}',
                      selected: false,
                      background: AppColors.surfaceMuted,
                    ),
                ],
              ),
            ),
          ],
          if (emptyNest) ...[
            const SizedBox(height: 6),
            NestCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set up your nest budget',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick a monthly spending target, log a few expenses, and track bills so nothing slips.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        showBudgetSheet(context, ref, current: safeBudget),
                    child: const Text('Set month budget'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: () => showBillSheet(context, ref),
                    child: const Text('Add a bill'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          const SectionLabel('Recent'),
          expensesAsync.when(
            loading: () => const NestLoadingSkeleton(itemCount: 2),
            error: (e, _) => NestCard(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return NestCard(
                  child: Text(
                    emptyNest
                        ? 'No expenses yet — tap + when you spend.'
                        : 'No expenses this nest yet. Tap + to add one.',
                    style: const TextStyle(color: AppColors.inkMuted),
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
            data: (billsList) {
              if (billsList.isEmpty) {
                return NestCard(
                  child: Text(
                    emptyNest
                        ? 'Track rent, utilities, and subscriptions here.'
                        : 'No bills tracked yet.',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                );
              }
              return NestCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < billsList.length; i++) ...[
                      _BillTile(
                        bill: billsList[i],
                        currency: currency,
                        onOpen: () => showBillSheet(
                          context,
                          ref,
                          existing: billsList[i],
                        ),
                        onToggle: () => _toggleBillPaid(
                          context,
                          ref,
                          billsList[i],
                        ),
                      ),
                      if (i != billsList.length - 1)
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

  static bool _isOverdue(Bill bill) {
    if (bill.paid) return false;
    final now = DateTime.now();
    final due = DateTime(bill.dueAt.year, bill.dueAt.month, bill.dueAt.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  static String _dueLabel(Bill bill) {
    if (bill.paid) return 'Paid';
    final now = DateTime.now();
    final due = DateTime(bill.dueAt.year, bill.dueAt.month, bill.dueAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = due.difference(today).inDays;
    if (days < 0) {
      final n = -days;
      return n == 1
          ? 'Overdue · 1 day · ${DateFormat.MMMd().format(bill.dueAt)}'
          : 'Overdue · $n days · ${DateFormat.MMMd().format(bill.dueAt)}';
    }
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days · ${DateFormat.MMMd().format(bill.dueAt)}';
  }

  static Future<void> _toggleBillPaid(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) async {
    final markingPaid = !bill.paid;
    await ref.read(billRepositoryProvider).togglePaid(bill);
    try {
      await ref.read(notificationServiceProvider).rescheduleBillReminders();
    } catch (_) {}
    await syncAfterWrite(ref, context: context, quiet: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          markingPaid ? 'Marked “${bill.title}” paid' : 'Marked unpaid',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final latest = (await ref.read(billsProvider.future))
                .where((b) => b.id == bill.id)
                .firstOrNull;
            final target = latest ?? bill.copyWith(paid: markingPaid);
            await ref.read(billRepositoryProvider).togglePaid(target);
            try {
              await ref
                  .read(notificationServiceProvider)
                  .rescheduleBillReminders();
            } catch (_) {}
            await syncAfterWrite(ref, context: context, quiet: true);
          },
        ),
      ),
    );
  }

  static Future<void> showBudgetSheet(
    BuildContext context,
    WidgetRef ref, {
    required double current,
  }) async {
    final controller = TextEditingController(
      text: current == current.roundToDouble()
          ? current.toStringAsFixed(0)
          : current.toStringAsFixed(2),
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return sheetBody(
          context: context,
          children: [
            sheetHandle(),
            const SizedBox(height: 6),
            const Text(
              'Month budget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your family’s spending target for this calendar month.',
              style: TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              onSubmitted: (value) {
                final parsed = double.tryParse(value.trim());
                if (parsed != null && parsed > 0) {
                  Navigator.pop(context, parsed);
                }
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final amount in const [1000.0, 1500.0, 1800.0, 2500.0, 3000.0])
                  SoftPill(
                    label: NumberFormat.simpleCurrency().format(amount),
                    selected: current == amount,
                    onTap: () => Navigator.pop(context, amount),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) return;
                Navigator.pop(context, parsed);
              },
              child: const Text('Save budget'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) return;
    await ref.read(expenseRepositoryProvider).setMonthBudget(result);
    await syncAfterWrite(ref, context: context);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Month budget set to ${NumberFormat.simpleCurrency().format(result)}',
        ),
      ),
    );
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
      await syncAfterWrite(ref, context: context);
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
    await syncAfterWrite(ref, context: context);
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
      await syncAfterWrite(ref, context: context);
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
    await syncAfterWrite(ref, context: context);
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({
    required this.bill,
    required this.currency,
    required this.onOpen,
    required this.onToggle,
  });

  final Bill bill;
  final NumberFormat currency;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final overdue = ExpensesScreen._isOverdue(bill);
    return ListTile(
      onTap: onOpen,
      leading: IconButton(
        tooltip: bill.paid ? 'Mark unpaid' : 'Mark paid',
        onPressed: onToggle,
        icon: Icon(
          bill.paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: bill.paid
              ? AppColors.tileGreen
              : overdue
                  ? AppColors.danger
                  : AppColors.tileOrange,
        ),
      ),
      title: Text(
        bill.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: overdue ? AppColors.danger : AppColors.ink,
        ),
      ),
      subtitle: Text(
        ExpensesScreen._dueLabel(bill),
        style: TextStyle(
          fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
          color: overdue ? AppColors.danger : AppColors.inkMuted,
        ),
      ),
      trailing: Text(
        currency.format(bill.amount),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: overdue ? AppColors.danger : AppColors.ink,
        ),
      ),
    );
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
