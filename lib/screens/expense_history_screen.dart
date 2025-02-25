import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  Box<ExpenseModel>? _expensesBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _expensesBox = await Hive.openBox<ExpenseModel>('expenses');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _expensesBox!.listenable(),
              builder: (context, Box<ExpenseModel> box, _) {
                if (box.isEmpty) {
                  return const Center(
                    child: Text('No expenses recorded yet'),
                  );
                }

                final expenses = box.values.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ExpenseListItem(expense: expense);
                  },
                );
              },
            ),
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseListItem({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(expense.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  expense.category == 'Shopping'
                      ? Icons.shopping_bag
                      : expense.category == 'Food'
                          ? Icons.restaurant
                          : expense.category == 'Transport'
                              ? Icons.directions_car
                              : expense.category == 'Entertainment'
                                  ? Icons.movie
                                  : expense.category == 'Bills'
                                      ? Icons.receipt_long
                                      : expense.category == 'Health'
                                          ? Icons.medical_services
                                          : expense.category == 'Education'
                                              ? Icons.school
                                              : Icons.category,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  expense.category,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  expense.paymentMethod == 'Cash'
                      ? Icons.money
                      : expense.paymentMethod == 'UPI'
                          ? Icons.mobile_friendly
                          : expense.paymentMethod == 'Debit Card'
                              ? Icons.credit_card
                              : expense.paymentMethod == 'Credit Card'
                                  ? Icons.credit_score
                                  : Icons.account_balance,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  expense.paymentMethod,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (expense.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                expense.comment,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
