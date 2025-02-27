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
  final TextEditingController _searchController = TextEditingController();
  List<ExpenseModel>? _filteredExpenses;
  static const int _itemsPerPage = 10;
  int _currentPage = 0;
  bool _hasMoreItems = true;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        return const Color(0xFF3498db); // Flat blue
      case 'Food':
        return const Color(0xFFe74c3c); // Flat red
      case 'Transport':
        return const Color(0xFFf39c12); // Flat orange
      case 'Entertainment':
        return const Color(0xFF9b59b6); // Flat purple
      case 'Bills':
        return const Color(0xFF1abc9c); // Flat turquoise
      case 'Health':
        return const Color(0xFF2ecc71); // Flat green
      case 'Education':
        return const Color(0xFFd35400); // Flat pumpkin
      default:
        return const Color(0xFF7f8c8d); // Flat gray
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

  void _filterExpenses(String searchText) {
    // Reset pagination whenever filter changes
    setState(() {
      _currentPage = 0;
      _hasMoreItems = true;
    });

    if (searchText.isEmpty) {
      setState(() => _filteredExpenses = null);
      return;
    }

    final List<ExpenseModel> allExpenses = _expensesBox!.values.toList();
    final query = searchText.toLowerCase();

    // Try to parse as a date query
    try {
      // Handle year only (e.g., "2025")
      if (RegExp(r'^\d{4}$').hasMatch(query)) {
        final year = int.parse(query);
        _filterByYear(allExpenses, year);
        return;
      }

      // Handle day only (e.g., "24")
      if (RegExp(r'^\d{1,2}$').hasMatch(query)) {
        final day = int.parse(query);
        if (day >= 1 && day <= 31) {
          _filterByDay(allExpenses, day);
          return;
        }
      }

      // Handle month name only (e.g., "February")
      if (RegExp(r'^[A-Za-z]+$').hasMatch(query)) {
        final monthName =
            query[0].toUpperCase() + query.substring(1).toLowerCase();
        try {
          final monthNumber = DateFormat('MMMM').parse(monthName).month;
          final now = DateTime.now();
          _filterByMonth(allExpenses, monthNumber, now.year);
          return;
        } catch (e) {
          // Not a valid month name, continue to other checks
        }
      }

      // Handle "February 2025" or "2025 February" format
      final yearMonthPattern1 = RegExp(r'^([A-Za-z]+)\s+(\d{4})$');
      final yearMonthPattern2 = RegExp(r'^(\d{4})\s+([A-Za-z]+)$');
      if (yearMonthPattern1.hasMatch(query) ||
          yearMonthPattern2.hasMatch(query)) {
        final parts = query.split(' ');
        final year =
            int.parse(parts.firstWhere((p) => RegExp(r'^\d{4}$').hasMatch(p)));
        final monthText =
            parts.firstWhere((p) => RegExp(r'^[A-Za-z]+$').hasMatch(p));
        final monthName =
            monthText[0].toUpperCase() + monthText.substring(1).toLowerCase();
        final monthNumber = DateFormat('MMMM').parse(monthName).month;
        _filterByMonth(allExpenses, monthNumber, year);
        return;
      }

      // Handle "February 24" format
      final monthDayPattern = RegExp(r'^([A-Za-z]+)\s+(\d{1,2})$');
      if (monthDayPattern.hasMatch(query)) {
        final parts = query.split(' ');
        final monthText = parts[0];
        final monthName =
            monthText[0].toUpperCase() + monthText.substring(1).toLowerCase();
        final monthNumber = DateFormat('MMMM').parse(monthName).month;
        final day = int.parse(parts[1]);
        final now = DateTime.now();
        _filterByMonthAndDay(allExpenses, monthNumber, day, now.year);
        return;
      }

      // Handle "24 February" format
      final dayMonthPattern = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)$');
      if (dayMonthPattern.hasMatch(query)) {
        final parts = query.split(' ');
        final day = int.parse(parts[0]);
        final monthText = parts[1];
        final monthName =
            monthText[0].toUpperCase() + monthText.substring(1).toLowerCase();
        final monthNumber = DateFormat('MMMM').parse(monthName).month;
        final now = DateTime.now();
        _filterByMonthAndDay(allExpenses, monthNumber, day, now.year);
        return;
      }
    } catch (e) {
      // If date parsing fails, fall back to regular search
    }

    // Regular search through all fields
    setState(() {
      _filteredExpenses = allExpenses.where((expense) {
        return expense.category.toLowerCase().contains(query) ||
            expense.comment.toLowerCase().contains(query) ||
            expense.paymentMethod.toLowerCase().contains(query) ||
            expense.amount.toString().contains(query);
      }).toList();
    });
  }

  void _filterByYear(List<ExpenseModel> expenses, int year) {
    setState(() {
      _filteredExpenses = expenses.where((expense) {
        return expense.date.year == year;
      }).toList();
    });
  }

  void _filterByDay(List<ExpenseModel> expenses, int day) {
    setState(() {
      _filteredExpenses = expenses.where((expense) {
        return expense.date.day == day;
      }).toList();
    });
  }

  void _filterByMonth(List<ExpenseModel> expenses, int month, int year) {
    setState(() {
      _filteredExpenses = expenses.where((expense) {
        return expense.date.month == month && expense.date.year == year;
      }).toList();
    });
  }

  void _filterByMonthAndDay(
      List<ExpenseModel> expenses, int month, int day, int year) {
    setState(() {
      _filteredExpenses = expenses.where((expense) {
        return expense.date.month == month && expense.date.day == day;
      }).toList();
    });
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
              // Top Card with total spending
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ValueListenableBuilder(
                        valueListenable: _expensesBox!.listenable(),
                        builder: (context, Box<ExpenseModel> box, _) {
                          final expenses =
                              _filteredExpenses ?? box.values.toList();
                          double totalSpent = expenses.fold(
                              0, (sum, expense) => sum + expense.amount);

                          return Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                                    '₹${totalSpent.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              // Chart section - only show when not searching
              if (_searchController.text.isEmpty)
                SizedBox(
                  height: 250,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ValueListenableBuilder(
                          valueListenable: _expensesBox!.listenable(),
                          builder: (context, Box<ExpenseModel> box, _) {
                            if (box.isEmpty) {
                              return const Center(
                                child: Text('No expenses recorded yet'),
                              );
                            }
                            return _buildExpenseChart(box.values.toList());
                          },
                        ),
                ),
              if (_searchController.text.isEmpty) const SizedBox(height: 16),
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: _filterExpenses,
                decoration: InputDecoration(
                  hintText: 'Search expenses or dates...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.5),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                cursorColor: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              // Expense list
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
                        final expenses =
                            _filteredExpenses ?? box.values.toList();
                        return _buildExpenseList(expenses);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<ExpenseModel> expenses) {
    // Sort expenses by date, most recent first
    expenses.sort((a, b) => b.date.compareTo(a.date));

    // Calculate pagination
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex =
        min((_currentPage + 1) * _itemsPerPage, expenses.length);
    final List<ExpenseModel> paginatedExpenses =
        expenses.sublist(startIndex, endIndex);

    _hasMoreItems = endIndex < expenses.length;

    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses found'),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paginatedExpenses.length,
          itemBuilder: (context, index) {
            final expense = paginatedExpenses[index];
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
                        color: _getCategoryColor(expense.category)
                            .withOpacity(0.15),
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
                              fontWeight: FontWeight.w500,
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
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
        const SizedBox(height: 16),
        // Simplified pagination controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _currentPage > 0
                  ? () => setState(() {
                        _currentPage--;
                      })
                  : null,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: _currentPage > 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  Text(
                    'Previous',
                    style: TextStyle(
                      color: _currentPage > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _hasMoreItems
                  ? () => setState(() {
                        _currentPage++;
                      })
                  : null,
              child: Row(
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      color: _hasMoreItems
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _hasMoreItems
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseChart(List<ExpenseModel> expenses) {
    Map<String, double> categoryTotals = {};
    double totalSpent = 0;
    double maxAmount = 0;

    // Calculate totals and find max amount
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
      totalSpent += expense.amount;
      if (categoryTotals[expense.category]! > maxAmount) {
        maxAmount = categoryTotals[expense.category]!;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
              labelRotation: 0,
              labelPosition: ChartDataLabelPosition.outside,
              labelAlignment: LabelAlignment.center,
              axisLabelFormatter: (axisLabelRenderArgs) {
                return ChartAxisLabel(
                    _getShortCategoryName(axisLabelRenderArgs.text),
                    axisLabelRenderArgs.textStyle);
              },
            ),
            primaryYAxis: NumericAxis(
              isVisible: false,
              maximum: maxAmount * 1.2,
            ),
            series: <ChartSeries>[
              // Single series with track
              ColumnSeries<MapEntry<String, double>, String>(
                dataSource: categoryTotals.entries.toList(),
                xValueMapper: (entry, _) => entry.key,
                yValueMapper: (entry, _) => entry.value,
                width: 0.8,
                spacing: 0.2,
                pointColorMapper: (entry, _) => _getCategoryColor(entry.key),
                borderRadius: BorderRadius.circular(16),
                // Add track settings here
                trackColor:
                    const Color.fromARGB(255, 201, 201, 201).withOpacity(0.15),
                trackBorderWidth: 0,
                trackPadding: 0,
                isTrackVisible: true,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.top,
                  builder: (data, point, series, pointIndex, seriesIndex) {
                    final MapEntry<String, double> entry =
                        data as MapEntry<String, double>;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${point.y.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
