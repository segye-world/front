import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_model.dart';
import '../models/todo_model.dart';
import 'notification_planner.dart';
import 'notification_settings.dart';
import 'schedule_api.dart';
import 'todo_api.dart';

/// 기기 로컬 예약 알림. 서버 푸시 없이, 일정·할 일이 바뀔 때마다
/// 앞으로 [_syncDays]일치 알림을 전부 지우고 다시 겁니다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _syncDays = 7;
  static const _permissionAskedKey = 'notif_permission_asked';
  static const _channelId = 'todo_reminders';
  static const _channelName = '할 일 알림';
  static const _channelDescription = '일정 시작·종료 전과 하루 마무리 때 남은 할 일을 알려드려요';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _debounce;
  Future<void>? _running;
  bool _rerun = false;
  // 로그아웃 시 올라갑니다. 진행 중이던 동기화가 로그아웃 뒤에 알림을 다시 걸지 못하게 막습니다.
  int _generation = 0;

  /// Android 에서만 동작합니다. 그 밖의 플랫폼과 테스트에서는 모든 호출이 아무 일도 하지 않습니다.
  bool get isSupported => _ready;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notify'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('알림 초기화 실패: $e');
    }
  }

  Future<bool> isPermitted() async {
    if (!_ready) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  Future<void> openSystemSettings() async {
    if (!_ready) return;
    await _android?.openAppNotificationSettings();
  }

  /// 로그인 직후 호출합니다. 처음 한 번만 권한을 묻고, 알림을 다시 계산합니다.
  Future<void> onLogin() async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_permissionAskedKey) ?? false)) {
      await prefs.setBool(_permissionAskedKey, true);
      await requestPermission();
    }
    await sync();
  }

  /// 로그아웃·회원 탈퇴 시 예약된 알림을 모두 지웁니다.
  Future<void> clear() async {
    _generation++;
    _debounce?.cancel();
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// 일정·할 일을 바꾼 뒤 호출합니다. 연달아 바뀌는 경우(일정 + 할 일 여러 개 생성)를 한 번으로 묶습니다.
  void requestSync() {
    if (!_ready) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), sync);
  }

  /// 동시에 두 번 돌면 cancelAll 과 예약이 뒤섞이므로 한 번에 하나만 돌리고, 도중에 요청이 오면 끝난 뒤 한 번 더 돕니다.
  Future<void> sync() {
    if (!_ready) return Future.value();
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    return _running = _syncLoop().whenComplete(() => _running = null);
  }

  Future<void> _syncLoop() async {
    do {
      _rerun = false;
      await _syncOnce();
    } while (_rerun);
  }

  Future<void> _syncOnce() async {
    final generation = _generation;
    try {
      final settings = await NotificationSettings.load();
      var planned = const <PlannedNotification>[];
      if (settings.anyEnabled) {
        final (schedules, todos) = await _fetchUpcoming();
        planned = planNotifications(
          schedules: schedules,
          todos: todos,
          settings: settings,
          now: DateTime.now(),
        );
      }
      if (generation != _generation) return;

      await _plugin.cancelAll();
      for (var i = 0; i < planned.length; i++) {
        final n = planned[i];
        await _plugin.zonedSchedule(
          id: i,
          title: n.title,
          body: n.body,
          // 절대 시각만 넘기면 되므로 기기 시간대 데이터 없이 UTC 로 변환해 넘깁니다.
          scheduledDate: tz.TZDateTime.from(n.at, tz.UTC),
          notificationDetails: _details(n.body),
          // 정확한 알람(SCHEDULE_EXACT_ALARM)은 Android 14+ 에서 사용자 승인이 필요해 쓰지 않습니다.
          // 절전 중에는 몇 분 늦게 울릴 수 있습니다.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('알림 재계산 실패: $e');
    }
  }

  Future<(List<ScheduleModel>, List<TodoModel>)> _fetchUpcoming() async {
    final now = DateTime.now();
    final dates = List.generate(
      _syncDays,
      (i) => _formatDate(DateTime(now.year, now.month, now.day + i)),
    );
    final perDay = await Future.wait(dates.map((date) async {
      final results = await Future.wait([
        ScheduleApi.fetchByDate(date),
        TodoApi.fetchByDate(date),
      ]);
      return (results[0] as List<ScheduleModel>, results[1] as List<TodoModel>);
    }));
    return (
      [for (final day in perDay) ...day.$1],
      [for (final day in perDay) ...day.$2],
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      );
}
