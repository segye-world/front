import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/screen/day/day_detail__screen.dart';

void main() {
  // 하루 = 날짜 머리글 26 + 24시간 × 28 = 698
  const day = 698.0;

  group('visibleDayOffsetFor', () {
    test('기준 날짜 안에서는 0 이다', () {
      expect(visibleDayOffsetFor(0), 0);
      expect(visibleDayOffsetFor(day - 1), 0);
    });

    test('다음 날 머리글이 맨 위에 닿으면 다음 날이 된다', () {
      expect(visibleDayOffsetFor(day), 1);
      expect(visibleDayOffsetFor(day * 2 + 100), 2);
    });

    test('위로 올려 전날이 보이면 음수가 된다', () {
      expect(visibleDayOffsetFor(-1), -1);
      expect(visibleDayOffsetFor(-day), -1);
      expect(visibleDayOffsetFor(-day - 1), -2);
    });

    test('경계의 부동소수 오차에도 날짜가 흔들리지 않는다', () {
      expect(visibleDayOffsetFor(day - 0.0001), 1);
    });
  });
}
