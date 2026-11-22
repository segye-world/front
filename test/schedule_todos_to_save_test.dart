import 'package:flutter_test/flutter_test.dart';
import 'package:segye_world/screen/day/day_detail__screen.dart';

void main() {
  group('scheduleTodosToSave', () {
    test('입력칸에 남은 할 일을 칩 뒤에 덧붙인다', () {
      expect(scheduleTodosToSave(['장보기'], '  운동  '), ['장보기', '운동']);
    });

    test('칩이 없어도 입력칸의 할 일을 저장한다', () {
      expect(scheduleTodosToSave([], '운동'), ['운동']);
    });

    test('공백만 있는 입력은 무시한다', () {
      expect(scheduleTodosToSave(['장보기'], '   '), ['장보기']);
    });

    test('이미 같은 칩이 있으면 한 번만 저장한다', () {
      expect(scheduleTodosToSave(['운동'], '운동'), ['운동']);
    });

    test('넘겨받은 칩 목록은 바꾸지 않는다', () {
      final drafts = ['장보기'];
      scheduleTodosToSave(drafts, '운동');
      expect(drafts, ['장보기']);
    });
  });
}
