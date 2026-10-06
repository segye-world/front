import 'package:shared_preferences/shared_preferences.dart';

/// 마이페이지 > 알림 설정의 사용자 선택값. 기기에만 저장합니다.
class NotificationSettings {
  static const _scheduleStartKey = 'notif_schedule_start';
  static const _scheduleEndKey = 'notif_schedule_end';
  static const _dailyWrapUpKey = 'notif_daily_wrap_up';

  /// 일정 시작 30분 전, 그 일정의 할 일 안내
  final bool scheduleStart;

  /// 일정 종료 10분 전, 미완료 할 일이 있을 때만
  final bool scheduleEnd;

  /// 22시 하루 마무리, 그날 미완료 할 일이 있을 때만
  final bool dailyWrapUp;

  const NotificationSettings({
    this.scheduleStart = true,
    this.scheduleEnd = true,
    this.dailyWrapUp = true,
  });

  bool get anyEnabled => scheduleStart || scheduleEnd || dailyWrapUp;

  NotificationSettings copyWith({
    bool? scheduleStart,
    bool? scheduleEnd,
    bool? dailyWrapUp,
  }) =>
      NotificationSettings(
        scheduleStart: scheduleStart ?? this.scheduleStart,
        scheduleEnd: scheduleEnd ?? this.scheduleEnd,
        dailyWrapUp: dailyWrapUp ?? this.dailyWrapUp,
      );

  static Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = NotificationSettings();
    return NotificationSettings(
      scheduleStart: prefs.getBool(_scheduleStartKey) ?? defaults.scheduleStart,
      scheduleEnd: prefs.getBool(_scheduleEndKey) ?? defaults.scheduleEnd,
      dailyWrapUp: prefs.getBool(_dailyWrapUpKey) ?? defaults.dailyWrapUp,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scheduleStartKey, scheduleStart);
    await prefs.setBool(_scheduleEndKey, scheduleEnd);
    await prefs.setBool(_dailyWrapUpKey, dailyWrapUp);
  }
}
