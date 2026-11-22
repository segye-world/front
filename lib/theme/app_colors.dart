import 'package:flutter/material.dart';

/// 앱 전체에서 공유하는 색상 토큰.
///
/// 화면마다 제각각 하드코딩되어 있던 브랜드/회색 계열 색상을 여기 하나로
/// 모아, 새 화면을 만들거나 기존 화면을 고칠 때 항상 이 상수만 참조하도록 합니다.
class AppColors {
  AppColors._();

  // ── 브랜드 컬러 ────────────────────────────────────────────────────────
  /// 앱의 메인 포인트 컬러(군청). 버튼, 선택 상태, 상단바 제목·아이콘, 보조 라벨 등
  /// 강조가 필요한 곳에 씁니다.
  ///
  /// 통일 이력
  /// - 분홍 계열(F7A5A5 / F3A3A4 / FFA4A9, 구 `primaryPink`)을 이 값으로 바꿨습니다.
  /// - 보조 네이비(6F7A9B, 구 `navy`)와 짙은 네이비(4F5E82, 구 `navyDark`.
  ///   그 전에는 53627D / 667195 / 7886A8 / 2F4B7C)를 이 값 하나로 합쳤습니다.
  static const Color primary = Color(0xFF5D688A);

  /// [primary]의 아주 옅은 배경 톤. 선택된 탭·강조 배너·선택 표시 배경 등에 씁니다.
  /// 기존 분홍 배경 톤(FFF1F1 / FFF4F4, 구 `primaryPinkTint`)을 대체합니다.
  /// [primary] 글자를 이 배경 위에 올리면 대비가 약 5:1 입니다.
  static const Color primaryTint = Color(0xFFEEF0F5);

  // ── 배경 / 표면 ────────────────────────────────────────────────────────
  /// 화면 기본 배경. 기존 F5F5F5 에서 흰색으로 바꿨습니다.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Colors.white;

  /// 입력창(TextField) 채움색. 기존 F8F9FB / F7F7F7 를 통일합니다.
  static const Color inputFill = Color(0xFFF8F9FB);

  // ── 테두리 ────────────────────────────────────────────────────────────
  /// 카드/컨테이너 테두리. 기존 EEE0E0 / DCD6D6 / E6DCDD / E1C9CC / E0E0E0 /
  /// E2E2E2 / EEEEEE / E7E7E7 를 이 값 하나로 통일했고, 군청 브랜드 색에 맞춰
  /// E6E6E6 에서 푸른 기가 도는 E7E9EF 로 바꿨습니다.
  static const Color cardBorder = Color(0xFFE7E9EF);

  /// 입력창 테두리. 카드 테두리와 역할이 달라 별도 토큰으로 둡니다.
  /// 기존 E0E3E8 / D2D7E2 를 통일합니다.
  static const Color inputBorder = Color(0xFFE0E3E8);

  // ── 텍스트 ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF242424);
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// 가장 옅은 보조 텍스트/아이콘. 기존 BABABA / B0B8C8 / 8B97B0 / B4BAC8 를
  /// 통일합니다.
  static const Color textTertiary = Color(0xFFB0B8C8);

  // ── 시맨틱 컬러 ────────────────────────────────────────────────────────
  /// 수입 텍스트(짙은 톤). 금액 표시 등 텍스트 위주 강조에 씁니다.
  static const Color income = Color(0xFF1B5E20);

  /// 수입 버튼/탭/스위치 등 UI 강조에 쓰는 밝은 톤.
  static const Color incomeAccent = Color(0xFF5AAD72);

  /// 지출 텍스트(짙은 톤).
  static const Color expense = Color(0xFFB71C1C);

  /// 지출 버튼/탭/스위치 등 UI 강조에 쓰는 밝은 톤.
  static const Color expenseAccent = Color(0xFFE05353);

  // ── 안내(경고) 배너 ────────────────────────────────────────────────────
  static const Color warningBackground = Color(0xFFFFF8F0);
  static const Color warningBorder = Color(0xFFFFE0B2);
  static const Color warningIcon = Color(0xFFE8A030);
  static const Color warningText = Color(0xFF795548);

  // ── 차트 전용 팔레트 ───────────────────────────────────────────────────
  /// 카테고리별 지출 차트처럼 수입/지출로 구분되지 않는 범주형 데이터에만 씁니다.
  static const Color chartBlue = Color(0xFF5E77FF);
  static const Color chartPurple = Color(0xFFB868FF);
}
