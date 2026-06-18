class CategoryModel {
  final int id;
  final String name;
  final String type; // 'EXPENSE' or 'INCOME'

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as int,
    name: json['name'] as String,
    // CategoryType enum 이름 그대로 반환됨 (EXPENSE / INCOME)
    type: (json['type'] as String?) ?? (json['categoryType'] as String? ?? ''),
  );
}

// 친구가 구현한 AccountRecord 백엔드 응답 형식에 맞춤:
// { id, categoryId, categoryName, categoryType, amount, transactionTime, scheduleId }
class AccountRecordModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categoryType; // 'EXPENSE' or 'INCOME'
  final int amount;          // 항상 양수 — categoryType으로 수입/지출 구분
  final int? scheduleId;

  const AccountRecordModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
    this.scheduleId,
  });

  factory AccountRecordModel.fromJson(Map<String, dynamic> json) =>
      AccountRecordModel(
        id: json['id'] as int,
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String? ?? '',
        categoryType: json['categoryType'] as String? ?? 'EXPENSE',
        // amount는 Long → int 캐스팅 (Dart int는 64bit이므로 안전)
        amount: (json['amount'] as num).toInt(),
        scheduleId: json['scheduleId'] as int?,
      );
}
