import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/screen/day/day_detail__screen.dart';

void main() {
  group('scheduleTransactionTime', () {
    test('일정 시작 시각을 거래 시각으로 사용한다', () {
      final time = scheduleTransactionTime(DateTime(2026, 9, 24), 14 * 60);
      expect(time, DateTime(2026, 9, 24, 14));
    });

    test('분 단위 시작 시각도 그대로 반영한다', () {
      final time = scheduleTransactionTime(DateTime(2026, 9, 24), 14 * 60 + 30);
      expect(time, DateTime(2026, 9, 24, 14, 30));
    });

    test('선택한 날짜의 기존 시각은 무시하고 시작 시각만 반영한다', () {
      final time = scheduleTransactionTime(DateTime(2026, 9, 24, 23, 59, 59), 9 * 60);
      expect(time, DateTime(2026, 9, 24, 9));
    });

    test('0시 일정은 00:00으로 저장된다', () {
      final time = scheduleTransactionTime(DateTime(2026, 9, 24), 0);
      expect(time, DateTime(2026, 9, 24, 0));
    });
  });
}
