import 'category_api.dart';

/// 회원별 금융 설정의 필수 기본값을 한 번 보장합니다.
/// 서버는 인증 토큰의 회원으로 저장하므로 기본값도 사용자별로 생성됩니다.
///
/// 수입원(지출 수단 겸용)과 지출 카테고리는 같은 Category 목록을 공유합니다.
/// 지출 카테고리 기본값은 없고(사용자가 직접 추가), 수입원 카테고리만 기본값을 보장합니다.
class FinanceSettingsApi {
  static const _incomeDefaults = ['월급', '현금', '부수입'];

  static Future<void> ensureDefaults() async {
    final categories = await CategoryApi.fetchAll();
    final incomes = categories
        .where((category) => category.type == 'INCOME')
        .map((category) => category.name)
        .toSet();

    await Future.wait([
      for (final name in _incomeDefaults.where((name) => !incomes.contains(name)))
        CategoryApi.create(name: name, type: 'INCOME'),
    ]);
  }
}
