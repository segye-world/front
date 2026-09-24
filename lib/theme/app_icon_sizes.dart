/// 앱 전체에서 공유하는 아이콘 크기 토큰.
///
/// 본문 안에서 쓰이는 인라인 아이콘(chevron, add 등)과 상단바/FAB처럼
/// 화면의 주요 액션을 나타내는 아이콘, 두 단계로 정리합니다.
class AppIconSize {
  AppIconSize._();

  /// 본문 인라인 아이콘. 예: 리스트의 chevron, 인라인 추가 버튼.
  static const double inline = 18;

  /// 상단바 뒤로가기, FAB, 하단 내비게이션처럼 화면의 주요 액션 아이콘.
  static const double action = 24;
}
