class PaymentMethodModel {
  final int id;
  final String name;

  const PaymentMethodModel({required this.id, required this.name});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id: (json['id'] ?? json['paymentMethodId']) as int,
        name: json['name'] as String,
      );
}
