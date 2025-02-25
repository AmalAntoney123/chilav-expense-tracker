import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  double totalBalance; // Budget total

  @HiveField(1)
  double savingsBalance;

  @HiveField(2)
  Map<String, double> categoryBudgets;

  @HiveField(3)
  double balance; // Actual balance

  BudgetModel({
    required this.totalBalance,
    required this.balance,
    required this.savingsBalance,
    required this.categoryBudgets,
  }) {
    // Ensure values are not null and are valid doubles
    this.totalBalance = totalBalance.toDouble();
    this.balance = balance.toDouble();
    this.savingsBalance = savingsBalance.toDouble();

    // Ensure all category budget values are valid doubles
    this.categoryBudgets = Map<String, double>.fromEntries(
      categoryBudgets.entries.map(
        (entry) => MapEntry(entry.key, entry.value.toDouble()),
      ),
    );
  }

  // Factory constructor to create a default budget
  factory BudgetModel.defaultBudget(List<String> categories) {
    return BudgetModel(
      totalBalance: 0.0,
      balance: 0.0,
      savingsBalance: 0.0,
      categoryBudgets: Map<String, double>.fromIterable(
        categories,
        value: (key) => 0.0,
      ),
    );
  }
}
