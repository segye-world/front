import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyNotificationSettingScreen extends StatefulWidget {
  const MyNotificationSettingScreen({super.key});

  @override
  State<MyNotificationSettingScreen> createState() =>
      _MyNotificationSettingScreenState();
}

class _MyNotificationSettingScreenState
    extends State<MyNotificationSettingScreen> {
  bool _dailyReminder = false;
  bool _scheduleAlert = false;
  bool _weeklyReport = false;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '알림 설정',
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _NotificationTile(
                  icon: Icons.alarm_outlined,
                  title: '일일 할 일 리마인더',
                  subtitle: '매일 오전 8시에 오늘의 할 일을 알려드려요',
                  value: _dailyReminder,
                  onChanged: (v) => setState(() => _dailyReminder = v),
                ),
                const SizedBox(height: 8),
                _NotificationTile(
                  icon: Icons.calendar_today_outlined,
                  title: '일정 시작 알림',
                  subtitle: '일정 시작 30분 전에 알려드려요',
                  value: _scheduleAlert,
                  onChanged: (v) => setState(() => _scheduleAlert = v),
                ),
                const SizedBox(height: 8),
                _NotificationTile(
                  icon: Icons.bar_chart_outlined,
                  title: '주간 소비 리포트',
                  subtitle: '매주 월요일에 지난 주 소비 내역을 요약해드려요',
                  value: _weeklyReport,
                  onChanged: (v) => setState(() => _weeklyReport = v),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBackground,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.warningIcon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '알림 기능은 준비 중입니다. 설정은 저장되지 않아요.',
                          style: TextStyle(fontSize: AppTextStyles.small.fontSize, color: AppColors.warningText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.mypage),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryPink,
          ),
        ],
      ),
    );
  }
}
