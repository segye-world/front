/// 하단 바처럼 화면 위에 떠 있는 반투명 유리(Liquid Glass) 표면의 강도 토큰.
///
/// HOME 에서 실기기로 확인해 최종값을 정하고(#95), CASH·MYPAGE 도 같은 값을 씁니다.
/// 하단 바는 앱 전체가 하나의 위젯([AppBottomNavBar])을 공유하므로 여기 값만
/// 바꾸면 모든 화면에 함께 반영됩니다.
class AppGlass {
  AppGlass._();

  /// 뒤 배경을 흐리게 하는 정도(블러 시그마, dp).
  static const double blurSigma = 14;

  /// 유리 표면(흰색)의 불투명도. 0이면 완전 투명, 1이면 불투명입니다.
  static const double opacity = 0.88;

  /// 블러 사용 여부. 저사양 기기에서 스크롤이 버벅이면 false 로 두고
  /// 불투명도만으로 유리 느낌을 냅니다.
  static const bool useBlur = true;
}
