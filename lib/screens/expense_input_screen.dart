import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';

class ExpenseInputScreen extends StatefulWidget {
  const ExpenseInputScreen({super.key});

  @override
  State<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  String _amount = '0';
  String _category = 'Shopping';
  String _paymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _commentController = TextEditingController();

  Timer? _backspaceTimer;

  final List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Debit Card',
    'Credit Card',
    'Net Banking',
  ];

  final List<String> _categories = [
    'Shopping',
    'Food',
    'Transport',
    'Entertainment',
    'Bills',
    'Health',
    'Education',
    'Others',
  ];

  void _updateAmount(String value) {
    setState(() {
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount += value;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _startBackspaceTimer() {
    _backspaceTimer?.cancel();
    _backspaceTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _backspace();
    });
  }

  void _stopBackspaceTimer() {
    _backspaceTimer?.cancel();
    _backspaceTimer = null;
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...(_paymentMethods.map((String method) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _paymentMethod = method;
                    });
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        method == 'Cash'
                            ? Icons.money
                            : method == 'UPI'
                                ? Icons.mobile_friendly
                                : method == 'Debit Card'
                                    ? Icons.credit_card
                                    : method == 'Credit Card'
                                        ? Icons.credit_score
                                        : Icons.account_balance,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        method,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: _paymentMethod == method
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _categories.map((String category) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _category = category;
                          });
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              category == 'Shopping'
                                  ? Icons.shopping_bag
                                  : category == 'Food'
                                      ? Icons.restaurant
                                      : category == 'Transport'
                                          ? Icons.directions_car
                                          : category == 'Entertainment'
                                              ? Icons.movie
                                              : category == 'Bills'
                                                  ? Icons.receipt_long
                                                  : category == 'Health'
                                                      ? Icons.medical_services
                                                      : category == 'Education'
                                                          ? Icons.school
                                                          : Icons.category,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            title: Text(
                              category,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            trailing: _category == category
                                ? Icon(Icons.check,
                                    color:
                                        Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_amount == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    try {
      final expensesBox = await Hive.openBox<ExpenseModel>('expenses');
      final budgetBox = await Hive.openBox<BudgetModel>('budget');
      final budget = budgetBox.get('current_budget');

      if (budget == null) {
        throw Exception('Budget not found');
      }

      final amount = double.parse(_amount);

      if (amount > budget.balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient balance')),
        );
        return;
      }

      final expense = ExpenseModel(
        amount: amount,
        category: _category,
        paymentMethod: _paymentMethod,
        comment: _commentController.text,
        date: _selectedDate,
      );

      await expensesBox.add(expense);

      budget.balance -= amount;
      await budgetBox.put('current_budget', budget);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving expense')),
        );
      }
    }
  }

  @override
  void dispose() {
    _backspaceTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New Expense',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category and Payment Method Selectors
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showPaymentMethodPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    _paymentMethod == 'Cash'
                                        ? Icons.money
                                        : _paymentMethod == 'UPI'
                                            ? Icons.mobile_friendly
                                            : _paymentMethod == 'Debit Card'
                                                ? Icons.credit_card
                                                : _paymentMethod ==
                                                        'Credit Card'
                                                    ? Icons.credit_score
                                                    : Icons.account_balance,
                                    color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_paymentMethod)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCategoryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    _category == 'Shopping'
                                        ? Icons.shopping_bag
                                        : _category == 'Food'
                                            ? Icons.restaurant
                                            : _category == 'Transport'
                                                ? Icons.directions_car
                                                : _category == 'Entertainment'
                                                    ? Icons.movie
                                                    : _category == 'Bills'
                                                        ? Icons.receipt_long
                                                        : _category == 'Health'
                                                            ? Icons
                                                                .medical_services
                                                            : _category ==
                                                                    'Education'
                                                                ? Icons.school
                                                                : Icons
                                                                    .category,
                                    color: colorScheme.tertiary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_category)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _amount,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLength: 50,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Add comment...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        counterText: '', // Hides the default counter
                        alignLabelWithHint: true,
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Number Pad and side buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '1',
                                  onTap: () => _updateAmount('1'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '2',
                                  onTap: () => _updateAmount('2'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '3',
                                  onTap: () => _updateAmount('3'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '4',
                                  onTap: () => _updateAmount('4'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '5',
                                  onTap: () => _updateAmount('5'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '6',
                                  onTap: () => _updateAmount('6'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '7',
                                  onTap: () => _updateAmount('7'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '8',
                                  onTap: () => _updateAmount('8'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '9',
                                  onTap: () => _updateAmount('9'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '₹',
                                  onTap: () {},
                                  colorScheme: colorScheme,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.1),
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '0',
                                  onTap: () => _updateAmount('0'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '.',
                                  onTap: () => _updateAmount('.'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      Column(
                        children: [
                          _NumberButton(
                            label: '',
                            icon: Icons.backspace,
                            onTap: _backspace,
                            onLongPressStart: (_) => _startBackspaceTimer(),
                            onLongPressEnd: (_) => _stopBackspaceTimer(),
                            colorScheme: colorScheme,
                            backgroundColor:
                                colorScheme.tertiary.withOpacity(0.6),
                            textColor: Colors.white.withOpacity(0.6),
                            height: 88,
                          ),
                          const SizedBox(height: 2),
                          _NumberButton(
                            label: '',
                            icon: Icons.calendar_today,
                            onTap: _selectDate,
                            colorScheme: colorScheme,
                            backgroundColor:
                                colorScheme.primary.withOpacity(0.6),
                            textColor: colorScheme.onPrimary,
                            height: 88,
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: _saveExpense,
                            child: Container(
                              width: 88,
                              height: 178,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 16), // Added to ensure space at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails)? onLongPressStart;
  final void Function(LongPressEndDetails)? onLongPressEnd;
  final ColorScheme colorScheme;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  const _NumberButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.colorScheme,
    this.backgroundColor,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        width: 88,
        height: height ?? 88,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: textColor ?? colorScheme.onSurface,
                  size: 24,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
