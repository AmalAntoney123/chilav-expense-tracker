import 'dart:math';

import 'package:chilav/screens/budget_allocation_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Shopping':
        return const Color(0xFF00BCD4); // Cyan
      case 'Food':
        return const Color(0xFFFF4081); // Pink
      case 'Transport':
        return const Color(0xFFFFEB3B); // Yellow
      case 'Entertainment':
        return const Color(0xFF7C4DFF); // Deep Purple
      case 'Bills':
        return const Color(0xFF4CAF50); // Green
      case 'Health':
        return const Color(0xFFFF5722); // Deep Orange
      case 'Education':
        return const Color(0xFF03A9F4); // Light Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills':
        return Icons.receipt;
      case 'Health':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  String _getShortCategoryName(String category) {
    switch (category) {
      case 'Shopping':
        return 'Shop';
      case 'Transport':
        return 'Trans';
      case 'Entertainment':
        return 'Ent';
      case 'Education':
        return 'Edu';
      default:
        return category.substring(0, min(4, category.length));
    }
  }

  Widget _buildExpenseList(List<ExpenseModel> expenses) {
    // Sort expenses by date, most recent first
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final subtextParts = [expense.paymentMethod];
        if (expense.comment.isNotEmpty) {
          subtextParts.insert(0, expense.comment);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        expense.date.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(expense.category),
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(expense.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(expense.category),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtextParts.join(' • '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseChart(List<ExpenseModel> expenses) {
    Map<String, double> categoryTotals = {};
    double totalSpent = 0;

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
      totalSpent += expense.amount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '₹ ${totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 200,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(color: Colors.black54),
              axisLabelFormatter: (axisLabelRenderArgs) {
                return ChartAxisLabel(
                    _getShortCategoryName(axisLabelRenderArgs.text),
                    axisLabelRenderArgs.textStyle);
              },
            ),
            primaryYAxis: NumericAxis(
              isVisible: false,
            ),
            series: <ChartSeries>[
              ColumnSeries<MapEntry<String, double>, String>(
                dataSource: categoryTotals.entries.toList(),
                xValueMapper: (entry, _) => entry.key,
                yValueMapper: (entry, _) => entry.value,
                pointColorMapper: (entry, _) => _getCategoryColor(entry.key),
                borderRadius: BorderRadius.circular(16),
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.top,
                  textStyle: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  labelPosition: ChartDataLabelPosition.outside,
                  builder: (data, point, series, pointIndex, seriesIndex) {
                    return Text(
                      '₹${point.y.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Top Card
              Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ValueListenableBuilder(
                                      valueListenable:
                                          _expensesBox!.listenable(),
                                      builder:
                                          (context, Box<ExpenseModel> box, _) {
                                        if (box.isEmpty) {
                                          return const Center(
                                            child: Text(
                                                'No expenses recorded yet'),
                                          );
                                        }
                                        final expenses = box.values.toList();
                                        return _buildExpenseChart(expenses);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Existing expense list
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ValueListenableBuilder(
                      valueListenable: _expensesBox!.listenable(),
                      builder: (context, Box<ExpenseModel> box, _) {
                        if (box.isEmpty) {
                          return const Center(
                            child: Text('No expenses recorded yet'),
                          );
                        }
                        final expenses = box.values.toList();
                        return _buildExpenseList(expenses);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseChartData {
  final String category;
  final double amount;
  final Color color;
  final int percentage;

  ExpenseChartData({
    required this.category,
    required this.amount,
    required this.color,
    required this.percentage,
  });
}
