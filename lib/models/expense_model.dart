import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 2)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String paymentMethod;

  @HiveField(3)
  final String comment;

  @HiveField(4)
  final DateTime date;

  ExpenseModel({
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.comment,
    required this.date,
  });
}