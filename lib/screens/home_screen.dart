import 'package:flutter/material.dart';
import 'budget_allocation_screen.dart';
import 'expense_input_screen.dart';
import 'expense_history_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isExtended = false;

  void _showExpenseInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        builder: (_, controller) => const ExpenseInputScreen(),
      ),
    );
  }

  void _showCustomizationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BudgetAllocation(),
      ),
    );
  }

  void _showExpenseHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseHistoryScreen(),
      ),
    );
  }

  Widget _buildRecentExpenses() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ExpenseModel>('expenses').listenable(),
      builder: (context, Box<ExpenseModel> box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Text('No recent expenses'),
          );
        }

        final expenses = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final recentExpenses = expenses.take(3).toList();

        return Column(
          children: recentExpenses
              .map(
                (expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExpenseItem(
                    amount: expense.amount,
                    category: expense.category,
                    date: _getRelativeDate(expense.date),
                    color: _getCategoryColor(expense.category),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Shopping':
        return Colors.blue;
      case 'Food':
        return Colors.red;
      case 'Transport':
        return Colors.green;
      case 'Entertainment':
        return Colors.purple;
      case 'Bills':
        return Colors.orange;
      case 'Health':
        return Colors.teal;
      case 'Education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: MouseRegion(
        onEnter: (_) => setState(() => _isExtended = true),
        onExit: (_) => setState(() => _isExtended = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: _isExtended
              ? FloatingActionButton.extended(
                  onPressed: _showExpenseInput,
                  backgroundColor: colorScheme.primary,
                  label: const Text('Add Expense'),
                  icon: const Icon(Icons.add),
                )
              : FloatingActionButton(
                  onPressed: _showExpenseInput,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.add),
                ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              // Progress indicator section
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: GestureDetector(
                                onTap: _showCustomizationScreen,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '84 %',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Plan Expenses',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 60,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: CustomPaint(
                                        painter: StripePainter(),
                                        child: Container(),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: 0.84,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$8,545',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Spent',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$10,000',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Budget',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Expenses History section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expenses History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_horiz),
                    onPressed: _showExpenseHistory,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Expense items
              _buildRecentExpenses(),
              const SizedBox(height: 24),
              // Bottom grid
              Row(
                children: [
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.shopping_bag,
                      label: 'Shopping',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.restaurant,
                      label: 'Food',
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
                    child: CategoryButton(
                      icon: Icons.directions_car,
                      label: 'Transport',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.movie,
                      label: 'Entertainment',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.receipt_long,
                      label: 'Bills',
                      color: colorScheme.primary,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.medical_services,
                      label: 'Health',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.school,
                      label: 'Education',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryButton(
                      icon: Icons.category,
                      label: 'Others',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseItem extends StatelessWidget {
  final double amount;
  final String category;
  final String date;
  final Color color;

  const ExpenseItem({
    super.key,
    required this.amount,
    required this.category,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹$amount.00',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.open_in_new,
                color: colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const CategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine if using tertiary color
    final isUsingTertiary = color == colorScheme.tertiary;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Icon in top left
            Align(
              alignment: Alignment.topLeft,
              child: Icon(
                icon,
                color: colorScheme.onSurface,
                size: 32,
              ),
            ),
            // Arrow in top right
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  color: isUsingTertiary ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.arrow_outward,
                  color: isUsingTertiary ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Text at bottom
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
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
      x += 12; // Adjust this value to change stripe density
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
