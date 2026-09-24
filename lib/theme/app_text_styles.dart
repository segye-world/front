import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전체에서 공유하는 텍스트 스타일 토큰.
///
/// fontSize 12종 / fontWeight 4종으로 흩어져 있던 화면별 텍스트 스타일을
/// 역할별 단계로 정리합니다. 화면마다 색상/굵기가 달라지는 경우
/// `copyWith(color: ..., fontWeight: ...)`로 확장해서 씁니다.
class AppTextStyles {
  AppTextStyles._();

  /// 화면/섹션 대제목. 예: 상단바 타이틀, 다이얼로그 제목.
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 섹션 소제목. 예: "비밀번호 변경", "지출 카테고리".
  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 본문 텍스트.
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 보조 설명 텍스트. 예: 리스트 아이템 부제, 안내 문구.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// 가장 작은 라벨/보조 액션 텍스트. 예: "전체 보기" 류의 보조 액션.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.navyDark,
  );

  // ── 위 5단계로 묶이지 않는 크기들 ──────────────────────────────────────
  // 화면마다 흩어져 있던 fontSize 직접 입력을 값만 통일합니다. 색상/굵기는
  // 화면별로 다르므로 각 호출부에서 copyWith로 지정합니다.

  /// 8pt. 차트 안의 아주 작은 보조 라벨.
  static const TextStyle micro = TextStyle(fontSize: 8, color: AppColors.textPrimary);

  /// 10pt. 카드 안 최소 단위 보조 텍스트(합계 라벨, 작은 배지 등).
  static const TextStyle tiny = TextStyle(fontSize: 10, color: AppColors.textPrimary);

  /// 11pt. 캡션보다 한 단계 작은 보조 텍스트(요일 라벨, 보조 배지 등).
  static const TextStyle small = TextStyle(fontSize: 11, color: AppColors.textPrimary);

  /// 15pt. 버튼 라벨 전용. [ThemeData.filledButtonTheme] 기본 텍스트 스타일과 값을 맞춥니다.
  static const TextStyle button = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  /// 18pt. 프로필 이니셜처럼 한 화면에서 크게 강조하는 텍스트.
  static const TextStyle emphasis = TextStyle(fontSize: 18, color: AppColors.textPrimary);

  /// 22pt. 금액 입력처럼 화면에서 가장 크게 강조하는 숫자.
  static const TextStyle amount = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
}
