import '../models/account_record_model.dart';
import '../models/payment_method_model.dart';
import 'category_api.dart';
import 'payment_method_api.dart';

/// 회원별 금융 설정의 필수 기본값을 한 번 보장합니다.
/// 서버는 인증 토큰의 회원으로 저장하므로 기본값도 사용자별로 생성됩니다.
class FinanceSettingsApi {
  static const _incomeDefaults = ['월급', '현금'];
  static const _paymentMethodDefaults = ['월급', '현금'];

  static Future<void> ensureDefaults() async {
    final results = await Future.wait([CategoryApi.fetchAll(), PaymentMethodApi.fetchAll()]);
    final categories = results[0] as List<CategoryModel>;
    final methods = results[1] as List<PaymentMethodModel>;
    final incomes = categories
        .where((category) => category.type == 'INCOME')
        .map((category) => category.name)
        .toSet();
    final paymentMethods = methods.map((method) => method.name).toSet();

    await Future.wait([
      for (final name in _incomeDefaults.where((name) => !incomes.contains(name)))
        CategoryApi.create(name: name, type: 'INCOME'),
      for (final name in _paymentMethodDefaults.where((name) => !paymentMethods.contains(name)))
        PaymentMethodApi.create(name: name),
    ]);
  }
}
