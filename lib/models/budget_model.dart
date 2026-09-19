class BudgetModel {
  final int id;
  final int year;
  final int month;
  final int limitAmount;

  const BudgetModel({
    required this.id,
    required this.year,
    required this.month,
    required this.limitAmount,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as int,
        year: json['year'] as int,
        month: json['month'] as int,
        limitAmount: (json['limitAmount'] as num).toInt(),
      );
}
