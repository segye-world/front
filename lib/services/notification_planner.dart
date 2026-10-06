import '../models/schedule_model.dart';
import '../models/todo_model.dart';
import 'notification_settings.dart';

class PlannedNotification {
  final DateTime at;
  final String title;
  final String body;

  /// 알림을 누르면 열 일정 상세 날짜(YYYY-MM-DD). 0시 일정의 시작 알림처럼 [at] 과 날짜가 다를 수 있습니다.
  final String date;

  const PlannedNotification({
    required this.at,
    required this.title,
    required this.body,
    required this.date,
  });

  @override
  String toString() => 'PlannedNotification($at, $date, $title, $body)';
}

const scheduleStartLead = Duration(minutes: 30);
const scheduleEndLead = Duration(minutes: 10);
const dailyWrapUpHour = 22;

/// 일정·할 일 스냅샷으로 앞으로 울릴 알림 목록을 만듭니다.
/// 데이터가 바뀔 때마다 전체를 다시 계산해 덮어쓰는 방식이라 순수 함수로 둡니다.
List<PlannedNotification> planNotifications({
  required List<ScheduleModel> schedules,
  required List<TodoModel> todos,
  required NotificationSettings settings,
  required DateTime now,
}) {
  final planned = <PlannedNotification>[];

  List<TodoModel> remainingOf(int scheduleId) =>
      todos.where((t) => t.scheduleId == scheduleId && !t.isDone).toList();

  for (final schedule in schedules) {
    final day = DateTime.parse(schedule.date);
    final remaining = remainingOf(schedule.id);
    // 남은 할 일이 없는 일정은 시작·종료 알림 모두 건너뜁니다.
    if (remaining.isEmpty) continue;

    if (settings.scheduleStart) {
      final start = DateTime(day.year, day.month, day.day, schedule.startHour);
      planned.add(PlannedNotification(
        at: start.subtract(scheduleStartLead),
        title: '30분 뒤 「${schedule.title}」 시작',
        body: '할 일 ${_summarize(remaining)}',
        date: schedule.date,
      ));
    }

    if (settings.scheduleEnd) {
      // endHour 는 24 까지 올 수 있고, DateTime 이 다음 날 0시로 넘겨 줍니다.
      final end = DateTime(day.year, day.month, day.day, schedule.endHour);
      planned.add(PlannedNotification(
        at: end.subtract(scheduleEndLead),
        title: '「${schedule.title}」 10분 뒤 종료',
        body: '아직 남은 할 일 ${_summarize(remaining)}',
        date: schedule.date,
      ));
    }
  }

  if (settings.dailyWrapUp) {
    final remainingByDate = <String, List<TodoModel>>{};
    for (final todo in todos.where((t) => !t.isDone)) {
      remainingByDate.putIfAbsent(todo.date, () => []).add(todo);
    }
    remainingByDate.forEach((date, remaining) {
      final day = DateTime.parse(date);
      planned.add(PlannedNotification(
        at: DateTime(day.year, day.month, day.day, dailyWrapUpHour),
        title: '오늘 하루 마무리',
        body: '끝내지 못한 할 일 ${_summarize(remaining)}',
        date: date,
      ));
    });
  }

  return planned.where((n) => n.at.isAfter(now)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
}

/// "3개 · 운동, 장보기 외 1개"
String _summarize(List<TodoModel> todos) {
  const shown = 2;
  final labels = todos.take(shown).map((t) => t.label).join(', ');
  final rest = todos.length - shown;
  return '${todos.length}개 · $labels${rest > 0 ? ' 외 $rest개' : ''}';
}
