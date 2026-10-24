import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/models/schedule_model.dart';
import 'package:segye_world/models/todo_model.dart';
import 'package:segye_world/services/notification_planner.dart';
import 'package:segye_world/services/notification_settings.dart';

ScheduleModel schedule(int id, {String date = '2026-10-06', int start = 14, int end = 16}) =>
    ScheduleModel(
      id: id,
      title: '일정$id',
      date: date,
      startHour: start,
      endHour: end,
      colorHex: '#F7A5A5',
    );

TodoModel todo(int id, {int? scheduleId, bool done = false, String date = '2026-10-06'}) =>
    TodoModel(id: id, scheduleId: scheduleId, label: '할일$id', isDone: done, date: date);

void main() {
  final morning = DateTime(2026, 10, 6, 9);
  const all = NotificationSettings();

  List<PlannedNotification> plan(
    List<ScheduleModel> schedules,
    List<TodoModel> todos, {
    NotificationSettings settings = all,
    DateTime? now,
  }) =>
      planNotifications(
        schedules: schedules,
        todos: todos,
        settings: settings,
        now: now ?? morning,
      );

  test('일정 시작 30분 전, 종료 10분 전, 22시 마무리를 시간순으로 만든다', () {
    final result = plan([schedule(1)], [todo(1, scheduleId: 1)]);

    expect(result.map((n) => n.at), [
      DateTime(2026, 10, 6, 13, 30),
      DateTime(2026, 10, 6, 15, 50),
      DateTime(2026, 10, 6, 22),
    ]);
    expect(result[0].title, contains('일정1'));
    expect(result[0].body, '할 일 1개 · 할일1');
  });

  test('할 일이 없는 일정은 시작·종료 알림을 건너뛴다', () {
    final result = plan([schedule(1)], []);
    expect(result, isEmpty);
  });

  test('할 일을 모두 끝낸 일정과 날짜는 알림이 없다', () {
    final result = plan([schedule(1)], [todo(1, scheduleId: 1, done: true)]);
    expect(result, isEmpty);
  });

  test('하루 마무리는 일정에 묶이지 않은 할 일도 센다', () {
    final result = plan([], [todo(1), todo(2), todo(3), todo(4, done: true)]);

    expect(result, hasLength(1));
    expect(result.single.at, DateTime(2026, 10, 6, 22));
    expect(result.single.body, '끝내지 못한 할 일 3개 · 할일1, 할일2 외 1개');
  });

  test('다른 일정의 할 일은 섞이지 않는다', () {
    final result = plan(
      [schedule(1), schedule(2, start: 18, end: 19)],
      [todo(1, scheduleId: 2)],
      settings: const NotificationSettings(dailyWrapUp: false),
    );

    expect(result.map((n) => n.at), [
      DateTime(2026, 10, 6, 17, 30),
      DateTime(2026, 10, 6, 18, 50),
    ]);
  });

  test('24시에 끝나는 일정은 23시 50분에 종료 알림', () {
    final result = plan(
      [schedule(1, start: 22, end: 24)],
      [todo(1, scheduleId: 1)],
      settings: const NotificationSettings(scheduleStart: false, dailyWrapUp: false),
    );

    expect(result.single.at, DateTime(2026, 10, 6, 23, 50));
  });

  test('0시에 시작하는 일정은 전날 23시 30분에 알리고, 누르면 일정 날짜를 연다', () {
    final result = plan(
      [schedule(1, date: '2026-10-07', start: 0, end: 1)],
      [todo(1, scheduleId: 1, date: '2026-10-07')],
      settings: const NotificationSettings(scheduleEnd: false, dailyWrapUp: false),
    );

    expect(result.single.at, DateTime(2026, 10, 6, 23, 30));
    expect(result.single.date, '2026-10-07');
  });

  test('이미 지난 시각의 알림은 빼고, 꺼진 항목은 만들지 않는다', () {
    final result = plan(
      [schedule(1)],
      [todo(1, scheduleId: 1)],
      settings: const NotificationSettings(scheduleEnd: false),
      now: DateTime(2026, 10, 6, 14),
    );

    expect(result.map((n) => n.at), [DateTime(2026, 10, 6, 22)]);
  });

  test('여러 날짜에 걸친 할 일은 날짜별로 마무리 알림을 만든다', () {
    final result = plan(
      [],
      [todo(1), todo(2, date: '2026-10-07')],
      settings: const NotificationSettings(scheduleStart: false, scheduleEnd: false),
    );

    expect(result.map((n) => n.at), [
      DateTime(2026, 10, 6, 22),
      DateTime(2026, 10, 7, 22),
    ]);
    expect(result.map((n) => n.date), ['2026-10-06', '2026-10-07']);
  });
}
