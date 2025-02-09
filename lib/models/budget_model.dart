import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  double totalBalance;

  @HiveField(1)
  double savingsBalance;

  @HiveField(2)
  Map<String, double> categoryBudgets;

  BudgetModel({
    required this.totalBalance,
    required this.savingsBalance,
    required this.categoryBudgets,
  });
}
