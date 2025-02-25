import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());

  // Clear existing boxes and reinitialize
  await _clearAndInitializeBoxes();

  runApp(const MyApp());
}

Future<void> _clearAndInitializeBoxes() async {
  // Clear existing boxes
  await Hive.deleteBoxFromDisk('budget');
  await Hive.deleteBoxFromDisk('expenses');

  // Initialize boxes with default data
  final budgetBox = await Hive.openBox<BudgetModel>('budget');
  final expensesBox = await Hive.openBox<ExpenseModel>('expenses');

  // Set default budget if empty
  if (budgetBox.isEmpty) {
    final defaultCategories = [
      'Shopping',
      'Food',
      'Transport',
      'Entertainment',
      'Bills',
      'Health',
      'Education',
      'Others',
    ];

    final defaultBudget = BudgetModel.defaultBudget(defaultCategories);
    await budgetBox.put('current_budget', defaultBudget);
  }

  // Close boxes
  await budgetBox.close();
  await expensesBox.close();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chilav',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 64, 136, 67),
          secondary: Colors.green.shade400,
          tertiary: const Color.fromARGB(255, 223, 62, 62),
          surface: const Color(0xFF1C1C1E),
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 76, 175, 120),
          secondary: const Color.fromARGB(255, 102, 187, 154),
          tertiary: const Color.fromARGB(255, 203, 75, 75),
          onSurface: const Color.fromARGB(255, 194, 193, 193),
          surface: const Color(0xFF1C1C1E),
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark, // Force dark theme
      home: const HomeScreen(),
    );
  }
}
