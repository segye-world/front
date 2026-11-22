import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/models/schedule_model.dart';

void main() {
  group('ScheduleModel.fromJson', () {
    test('분 단위 필드를 읽는다', () {
      final model = ScheduleModel.fromJson({
        'id': 1,
        'title': '회의',
        'date': '2026-11-22',
        'startMinute': 870,
        'endMinute': 970,
        'startHour': 14,
        'endHour': 17,
        'colorHex': '#5D688A',
      });

      expect(model.startMinute, 870);
      expect(model.endMinute, 970);
    });

    test('분 단위 필드가 없는 이전 서버 응답은 시를 분으로 바꾼다', () {
      final model = ScheduleModel.fromJson({
        'id': 1,
        'title': '회의',
        'date': [2026, 11, 22],
        'startHour': 7,
        'endHour': 24,
        'colorHex': '#5D688A',
      });

      expect(model.startMinute, 420);
      expect(model.endMinute, 1440);
      expect(model.date, '2026-11-22');
    });
  });
}
