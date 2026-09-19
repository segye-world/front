import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전체에서 공유하는 텍스트 스타일 토큰.
///
/// fontSize 12종 / fontWeight 4종으로 흩어져 있던 화면별 텍스트 스타일을
/// 역할별 5단계(title/subtitle/body/caption/label)로 정리합니다.
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
}
