/// 앱 전체에서 공유하는 모서리 반경 토큰.
///
/// 카드/버튼/다이얼로그에 2~28px 사이 11종이 흩어져 있던 것을
/// 역할별로 정리합니다. 색상 스와치, 프로그레스 바 캡처럼 카드가 아닌
/// 순수 장식용 모서리는 이 토큰의 대상이 아닙니다.
class AppRadius {
  AppRadius._();

  /// 리스트에 나열되는 작은 카드/컨테이너.
  static const double card = 14;

  /// 다이얼로그, 프로필 카드 등 화면에서 크게 보이는 섹션.
  static const double large = 20;

  /// 버튼, 입력창.
  static const double button = 12;
}
