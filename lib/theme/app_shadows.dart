import 'package:flutter/material.dart';

/// 앱 전체에서 공유하는 그림자 프리셋.
///
/// 카드/패널마다 제각각이던 BoxShadow 값을 정리합니다.
class AppShadows {
  AppShadows._();

  /// 화면 위에 떠 있는 카드(타임라인 이벤트 카드 등)에 쓰는 기본 그림자.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  /// 화면 가장자리에 붙는 패널(할 일/수입지출 패널 손잡이 등)의 그림자.
  static const List<BoxShadow> edgePanel = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(-2, 0),
    ),
  ];

  /// 드래그로 열리는 패널처럼 투명도가 애니메이션되는 가장자리 그림자.
  /// [openness]는 0(닫힘)~1(완전히 열림) 사이 값입니다.
  static List<BoxShadow> animatedEdgePanel(double openness) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12 * openness),
          blurRadius: 12,
          offset: const Offset(2, 0),
        ),
      ];
}
