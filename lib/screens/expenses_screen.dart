import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final progress = MockData.monthSpent / MockData.monthBudget;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          NestCard(
            color: AppColors.primary,
            padding: const EdgeInsets.all(20),
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
                  currency.format(MockData.monthSpent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of ${currency.format(MockData.monthBudget)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          const SectionLabel('Recent'),
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < MockData.expenses.length; i++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      MockData.expenses[i].title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${MockData.expenses[i].category} · ${MockData.expenses[i].by}',
                    ),
                    trailing: Text(
                      currency.format(MockData.expenses[i].amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (i != MockData.expenses.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Bills'),
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < MockData.bills.length; i++) ...[
                  ListTile(
                    leading: Icon(
                      MockData.bills[i].paid
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: MockData.bills[i].paid
                          ? AppColors.tileGreen
                          : AppColors.tileOrange,
                    ),
                    title: Text(
                      MockData.bills[i].title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(MockData.bills[i].dueLabel),
                    trailing: Text(
                      currency.format(MockData.bills[i].amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (i != MockData.bills.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
