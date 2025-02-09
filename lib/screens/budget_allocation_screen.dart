import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget_model.dart';

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
  late Box<BudgetModel> _budgetBox;
  double _totalBalance = 0.0;
  double _savingsBalance = 0.0;
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
    _initHive();
  }

  Future<void> _initHive() async {
    _budgetBox = await Hive.openBox<BudgetModel>('budget');
    _loadBudgetData();
  }

  void _loadBudgetData() {
    final budgetModel = _budgetBox.get('current_budget');
    if (budgetModel != null) {
      setState(() {
        _totalBalance = budgetModel.totalBalance;
        _savingsBalance = budgetModel.savingsBalance;
        _categoryBudgets =
            Map<String, double>.from(budgetModel.categoryBudgets);
      });
    }
  }

  Future<void> _saveBudgetData() async {
    final budgetModel = BudgetModel(
      totalBalance: _totalBalance,
      savingsBalance: _savingsBalance,
      categoryBudgets: _categoryBudgets,
    );
    await _budgetBox.put('current_budget', budgetModel);
  }

  void _showAddMoneyDialog() {
    double amount = 0;
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _totalBalance += amount;
              });
              Navigator.pop(context);
              _showSavingsPrompt(amount);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSavingsPrompt(double addedAmount) {
    double savingsAmount = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Savings?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Would you like to move some of ₹$addedAmount to savings?'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to save',
                prefixText: '₹',
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
          TextButton(
            onPressed: () {
              if (savingsAmount <= _totalBalance) {
                setState(() {
                  _totalBalance -= savingsAmount;
                  _savingsBalance += savingsAmount;
                });
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
                  _totalBalance += amount;
                });
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
    if (amountStr.length > 12) return 24;
    if (amountStr.length > 9) return 28;
    return 32;
  }

  void _showBudgetAllocationSheet() {
    final Map<String, double> tempBudgets = Map.from(_categoryBudgets);
    Map<String, bool> editingStates = Map.fromIterables(
      _categoryBudgets.keys,
      List.generate(_categoryBudgets.length, (_) => false),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            double getTotalAllocated() {
              return tempBudgets.values.fold(0, (sum, value) => sum + value);
            }

            void updateBudget(String category, double newValue) {
              double totalAfterChange =
                  getTotalAllocated() - (tempBudgets[category] ?? 0) + newValue;

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
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                          text: currentValue > 0 ? currentValue.toString() : '',
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
                              content: Text('Amount exceeds available budget'),
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
                        setState(() {
                          _totalBalance = newBudget;
                          // If new budget is less than current allocations, reset all
                          if (getTotalAllocated() > newBudget) {
                            tempBudgets.forEach((key, value) {
                              tempBudgets[key] = 0.0;
                            });
                          }
                        });
                        await _saveBudgetData();
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                          buildAmountInput(category, budget),
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
                                    thumbColor: _getCategoryColor(category),
                                    overlayColor: _getCategoryColor(category)
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
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Shopping':
        return Colors.blue;
      case 'Food':
        return Theme.of(context).colorScheme.tertiary;
      case 'Transport':
        return Colors.orange;
      case 'Entertainment':
        return Colors.purple;
      case 'Bills':
        return Theme.of(context).colorScheme.primary;
      case 'Health':
        return Colors.green;
      case 'Education':
        return Colors.amber;
      case 'Others':
        return Colors.grey;
      default:
        return Colors.grey;
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
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                GestureDetector(
                                  onTap: _showBudgetAllocationSheet,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹${_totalBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        _getBalanceFontSize(_totalBalance),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Budget',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.savings,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                GestureDetector(
                                  onTap: _showWithdrawFromSavings,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: const Icon(
                                      Icons.touch_app,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹${_savingsBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        _getBalanceFontSize(_savingsBalance),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Savings',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Category Allocations
              const Text(
                'Category Allocations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Shopping',
                      amount: 2000,
                      percentage: 20,
                      color: Colors.blue,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Food',
                      amount: 1500,
                      percentage: 15,
                      color: colorScheme.tertiary,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Transport',
                      amount: 1000,
                      percentage: 10,
                      color: Colors.orange,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Entertainment',
                      amount: 1000,
                      percentage: 10,
                      color: Colors.purple,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Bills',
                      amount: 2500,
                      percentage: 25,
                      color: colorScheme.primary,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Health',
                      amount: 1000,
                      percentage: 10,
                      color: Colors.green,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Education',
                      amount: 500,
                      percentage: 5,
                      color: Colors.amber,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BudgetCategoryItem(
                      category: 'Others',
                      amount: 500,
                      percentage: 5,
                      color: Colors.grey,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetCategoryItem extends StatelessWidget {
  final String category;
  final double amount;
  final int percentage;
  final Color color;
  final VoidCallback onTap;

  const BudgetCategoryItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '₹$amount',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      decoration: BoxDecoration(
        color: isAvailable
            ? colorScheme.tertiary.withOpacity(0.1)
            : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 8),
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
