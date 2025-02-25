// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BudgetAllocation extends StatefulWidget {
  const BudgetAllocation({super.key});

  @override
  State<BudgetAllocation> createState() => _BudgetAllocationState();
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
      return Icons.receipt_long;
    case 'Health':
      return Icons.medical_services;
    case 'Education':
      return Icons.school;
    case 'Others':
      return Icons.category;
    default:
      return Icons.category;
  }
}

class _BudgetAllocationState extends State<BudgetAllocation> {
  Box<BudgetModel>? _budgetBox;
  double _totalBalance = 0.0;
  double _balance = 0.0;
  double _savingsBalance = 0.0;
  bool _isInitialized = false;
  Map<String, double> _categoryBudgets = {
    'Shopping': 0,
    'Food': 0,
    'Transport': 0,
    'Entertainment': 0,
    'Bills': 0,
    'Health': 0,
    'Education': 0,
    'Others': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      _budgetBox = await Hive.openBox<BudgetModel>('budget');

      // Initialize with default values only if empty
      if (_budgetBox!.isEmpty) {
        final budgetModel =
            BudgetModel.defaultBudget(_categoryBudgets.keys.toList());
        await _budgetBox!.put('current_budget', budgetModel);
      }

      _loadBudgetData();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing Hive: $e');
      // Only reset to default values if we couldn't load existing data
      if (_budgetBox?.get('current_budget') == null) {
        setState(() {
          _totalBalance = 0.0;
          _balance = 0.0;
          _savingsBalance = 0.0;
          _categoryBudgets = Map<String, double>.fromIterable(
            _categoryBudgets.keys,
            value: (key) => 0.0,
          );
        });
      }
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _saveBudgetData() async {
    if (!_isInitialized || _budgetBox == null) {
      print('Budget box not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while the app initializes...'),
        ),
      );
      return;
    }

    try {
      final budgetModel = BudgetModel(
        totalBalance: _totalBalance,
        balance: _balance,
        savingsBalance: _savingsBalance,
        categoryBudgets: _categoryBudgets,
      );
      await _budgetBox!.put('current_budget', budgetModel);
    } catch (e) {
      print('Error saving budget data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving data. Please try again.'),
        ),
      );
    }
  }

  void _loadBudgetData() {
    if (_budgetBox == null) {
      print('Budget box is null during load');
      return;
    }

    try {
      final budgetModel = _budgetBox!.get('current_budget');
      if (budgetModel != null) {
        setState(() {
          _totalBalance = budgetModel.totalBalance;
          _balance = budgetModel.balance;
          _savingsBalance = budgetModel.savingsBalance;
          // Ensure we preserve all category keys
          final Map<String, double> newBudgets =
              Map<String, double>.from(_categoryBudgets);
          budgetModel.categoryBudgets.forEach((key, value) {
            if (newBudgets.containsKey(key)) {
              newBudgets[key] = value;
            }
          });
          _categoryBudgets = newBudgets;
        });
      }
    } catch (e) {
      print('Error loading budget data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading data. Please restart the app.'),
        ),
      );
    }
  }

  // Add this method to check initialization before any operation
  bool _checkInitialization() {
    if (!_isInitialized || _budgetBox == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while the app initializes...'),
        ),
      );
      return false;
    }
    return true;
  }

  void _showAddMoneyDialog() {
    if (!_checkInitialization()) return;
    double amount = 0;
    String source = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
              ),
              onChanged: (value) {
                amount = double.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Source',
                hintText: 'e.g., Salary, Freelance, etc.',
              ),
              onChanged: (value) {
                source = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                  ),
                );
                return;
              }
              setState(() {
                _balance += amount;
              });
              _saveBudgetData();
              Navigator.pop(context);
              _showSavingsPrompt(amount, source);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSavingsPrompt(double addedAmount, String source) {
    // Suggest 20% for savings
    double suggestedSavings = addedAmount * 0.20;
    double savingsAmount = suggestedSavings;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Savings?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Would you like to move some of ₹$addedAmount to savings?'),
            const SizedBox(height: 8),
            Text(
              'Suggested savings (20%): ₹${suggestedSavings.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to save',
                prefixText: '₹',
              ),
              controller: TextEditingController(
                text: suggestedSavings.toString(),
              ),
              onChanged: (value) {
                savingsAmount = double.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () {
              if (savingsAmount <= _balance) {
                setState(() {
                  _balance -= savingsAmount;
                  _savingsBalance += savingsAmount;
                });
                _saveBudgetData(); // Save the updated data
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient balance'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawFromSavings() {
    if (!_checkInitialization()) return;
    double amount = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw from Savings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Available in savings: ₹${_savingsBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to withdraw',
                prefixText: '₹',
              ),
              onChanged: (value) {
                amount = double.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (amount <= _savingsBalance) {
                setState(() {
                  _savingsBalance -= amount;
                  _balance += amount;
                });
                _saveBudgetData();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient savings'),
                  ),
                );
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  double _getBalanceFontSize(double amount) {
    String amountStr = amount.toStringAsFixed(2);
    if (amountStr.length > 12) return 32;
    if (amountStr.length > 9) return 36;
    return 40;
  }

  void _showBudgetAllocationSheet() {
    if (!_checkInitialization()) return;
    final Map<String, double> tempBudgets = Map.from(_categoryBudgets);
    Map<String, bool> editingStates = Map.fromIterables(
      _categoryBudgets.keys,
      List.generate(_categoryBudgets.length, (_) => false),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      elevation: 20,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              double getTotalAllocated() {
                return tempBudgets.values.fold(0, (sum, value) => sum + value);
              }

              void updateBudget(String category, double newValue) {
                double totalAfterChange = getTotalAllocated() -
                    (tempBudgets[category] ?? 0) +
                    newValue;

                if (totalAfterChange <= _totalBalance) {
                  setState(() {
                    tempBudgets[category] = newValue;
                  });
                }
              }

              Widget buildAmountInput(String category, double budget) {
                if (editingStates[category]!) {
                  return SizedBox(
                    width: 120,
                    height: 32,
                    child: TextFormField(
                      initialValue: budget > 0 ? budget.toString() : '',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        prefixText: '₹',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                      autofocus: true,
                      onFieldSubmitted: (value) {
                        double newValue = double.tryParse(value) ?? 0;
                        if (newValue <=
                            _totalBalance - (getTotalAllocated() - budget)) {
                          updateBudget(category, newValue);
                        }
                        setState(() {
                          editingStates[category] = false;
                        });
                      },
                      onTapOutside: (_) {
                        setState(() {
                          editingStates[category] = false;
                        });
                      },
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      editingStates[category] = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '₹${budget.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              void _editCategoryBudget(String category) {
                double currentValue = tempBudgets[category] ?? 0;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Edit $category Budget'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹',
                          ),
                          controller: TextEditingController(
                            text:
                                currentValue > 0 ? currentValue.toString() : '',
                          ),
                          onChanged: (value) {
                            currentValue = double.tryParse(value) ?? 0;
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (currentValue <=
                              _totalBalance -
                                  (getTotalAllocated() -
                                      (tempBudgets[category] ?? 0))) {
                            setState(() {
                              tempBudgets[category] = currentValue;
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Amount exceeds available budget'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              }

              void _editTotalBudget() {
                if (!_isInitialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please wait while the app initializes...'),
                    ),
                  );
                  return;
                }

                double newBudget = _totalBalance;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Edit Total Budget'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Budget',
                            prefixText: '₹',
                          ),
                          onChanged: (value) {
                            newBudget = double.tryParse(value) ?? _totalBalance;
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          try {
                            setState(() {
                              _totalBalance = newBudget;
                              // If new budget is less than current allocations, reset all
                              if (_getCategoryTotal() > newBudget) {
                                _categoryBudgets.forEach((key, value) {
                                  _categoryBudgets[key] = 0.0;
                                });
                              }
                            });
                            await _saveBudgetData();
                            Navigator.pop(context);
                          } catch (e) {
                            print('Error updating budget: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Error updating budget. Please try again.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Allocate Budget',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              GestureDetector(
                                onTap: _editTotalBudget,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit Total',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _BudgetInfoCard(
                                  title: 'Total Budget',
                                  amount: _totalBalance,
                                  icon: Icons.account_balance_wallet,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _BudgetInfoCard(
                                  title: 'Available',
                                  amount: _totalBalance - getTotalAllocated(),
                                  icon: Icons.savings,
                                  isAvailable: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _categoryBudgets.length,
                                itemBuilder: (context, index) {
                                  final category =
                                      _categoryBudgets.keys.elementAt(index);
                                  final budget = tempBudgets[category] ?? 0.0;
                                  final percentage = (_totalBalance > 0
                                          ? (budget / _totalBalance * 100)
                                          : 0.0)
                                      .round();

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getCategoryIcon(category),
                                            color: _getCategoryColor(category),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                buildAmountInput(
                                                    category, budget),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '$percentage%',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor:
                                              _getCategoryColor(category),
                                          inactiveTrackColor:
                                              _getCategoryColor(category)
                                                  .withOpacity(0.2),
                                          thumbColor:
                                              _getCategoryColor(category),
                                          overlayColor:
                                              _getCategoryColor(category)
                                                  .withOpacity(0.1),
                                        ),
                                        child: Slider(
                                          value: budget,
                                          min: 0,
                                          max: _totalBalance,
                                          onChanged: (value) {
                                            updateBudget(category, value);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                setState(() {
                                  _categoryBudgets = tempBudgets;
                                });
                                await _saveBudgetData();
                                Navigator.pop(context);
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
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
      case 'Others':
        return const Color(0xFF7f8c8d); // Flat gray
      default:
        return const Color(0xFF95a5a6); // Flat light gray
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
        return Icons.receipt_long;
      case 'Health':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      case 'Others':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    List<BudgetChartData> _getChartData() {
      return _categoryBudgets.entries.map((entry) {
        return BudgetChartData(
          category: entry.key,
          amount: entry.value,
          color: _getCategoryColor(entry.key),
          percentage: (_totalBalance > 0
              ? ((entry.value / _totalBalance) * 100).round()
              : 0),
        );
      }).toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Balance Cards
              Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Top row with back and edit buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 10, 10, 10),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showBudgetAllocationSheet,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Center balance amount
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '₹${_balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: _getBalanceFontSize(_balance),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Add the buttons here
                            Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 64,
                                    child: FilledButton.icon(
                                      onPressed: _showAddMoneyDialog,
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Add Money',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.horizontal(
                                            left: Radius.circular(22),
                                            right: Radius.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: 64,
                                    child: ClipRRect(
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                        right: Radius.circular(22),
                                      ),
                                      child: Material(
                                        color: Colors.white,
                                        child: InkWell(
                                          onTap: _showWithdrawFromSavings,
                                          child: Stack(
                                            children: [
                                              CustomPaint(
                                                size: const Size.fromHeight(64),
                                                painter: StripePainter(),
                                              ),
                                              Center(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.savings,
                                                      color: Colors.black,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '₹${_savingsBalance.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Balance text and value at bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Budget',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${_totalBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Card containing Category Allocations, chart and legend
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(0),
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.black, // Make card background dark
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Allocations heading
                      const Text(
                        'Category Allocations',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Make text white
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Chart
                      _buildPieChart(),
                      const SizedBox(height: 16),
                      // Legend Card
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _getChartData().map((data) {
                              final percentage = _totalBalance > 0
                                  ? ((data.amount / _totalBalance * 100)
                                      .round())
                                  : 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: data.color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        data.category,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '₹${data.amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '$percentage%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getCategoryTotal() {
    return _categoryBudgets.values.fold(0, (sum, value) => sum + value);
  }

  Widget _buildPieChart() {
    final List<BudgetChartData> chartData =
        _categoryBudgets.entries.where((entry) => entry.value > 0).map((entry) {
      double percentage =
          _totalBalance > 0 ? (entry.value / _totalBalance) * 100 : 0;
      return BudgetChartData(
        category: entry.key,
        amount: entry.value,
        color: _getCategoryColor(entry.key),
        percentage: percentage.toInt(),
      );
    }).toList();

    if (chartData.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Text(
            'No budget allocations yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return SfCircularChart(
      series: <CircularSeries>[
        DoughnutSeries<BudgetChartData, String>(
          dataSource: chartData,
          xValueMapper: (BudgetChartData data, _) => data.category,
          yValueMapper: (BudgetChartData data, _) => data.amount,
          pointColorMapper: (BudgetChartData data, _) => data.color,
          dataLabelMapper: (BudgetChartData data, _) => '${data.percentage}%',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.inside,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          enableTooltip: true,
          radius: '100%',
          innerRadius: '50%',
          strokeColor: Colors.black,
          strokeWidth: 4,
          selectionBehavior: SelectionBehavior(
            enable: true,
            toggleSelection: true,
            selectedBorderWidth: 3,
            selectedBorderColor: Colors.black,
            unselectedOpacity: 0.7,
          ),
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: ₹point.y',
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        color: Colors.white,
      ),
    );
  }
}

class BudgetChartData {
  final String category;
  final double amount;
  final Color color;
  final int percentage;

  BudgetChartData({
    required this.category,
    required this.amount,
    required this.color,
    required this.percentage,
  });
}

class _BudgetInfoCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final bool isAvailable;

  const _BudgetInfoCard({
    required this.title,
    required this.amount,
    required this.icon,
    this.isAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 100, // Add fixed height
      decoration: BoxDecoration(
        color: isAvailable
            ? colorScheme.tertiary.withOpacity(0.1)
            : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Add this
        crossAxisAlignment: CrossAxisAlignment.start, // Add this
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isAvailable ? colorScheme.tertiary : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(), // Replace Expanded with Spacer
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isAvailable ? colorScheme.tertiary : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    double x = -size.width;
    while (x < size.width * 2) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
      x += 12;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
