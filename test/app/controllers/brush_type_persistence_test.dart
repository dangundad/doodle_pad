import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';

/// Regression: 저장된 작품은 브러시를 stable ID로 기억한다.
/// enum 선언 순서를 바꿔도 기존 작품의 브러시 해석이 흔들리면 안 된다.
void main() {
  test('모든 BrushType에 stable ID가 누락 없이 부여되어 있다', () {
    final map = BrushTypePersistence.stableIdMapForTest;
    for (final type in BrushType.values) {
      expect(
        map.containsKey(type),
        isTrue,
        reason: '$type에 stable ID가 없다. _brushTypeStableIds에 추가해야 한다.',
      );
    }
  });

  test('stable ID는 서로 중복되지 않는다', () {
    final ids = BrushTypePersistence.stableIdMapForTest.values.toList();
    expect(ids.toSet().length, ids.length, reason: 'stable ID에 중복이 있다.');
  });

  test('stable ID 값은 고정되어 있다 (변경 시 기존 저장 데이터 깨짐)', () {
    // 이 기대값은 frozen이다. 누군가 ID를 바꾸면 이 테스트가 막아준다.
    expect(BrushType.pen.stableId, 0);
    expect(BrushType.pencil.stableId, 1);
    expect(BrushType.marker.stableId, 2);
    expect(BrushType.brush.stableId, 3);
    expect(BrushType.highlighter.stableId, 4);
    expect(BrushType.fountainPen.stableId, 5);
    expect(BrushType.crayon.stableId, 6);
    expect(BrushType.watercolor.stableId, 7);
    expect(BrushType.airbrush.stableId, 8);
    expect(BrushType.eraser.stableId, 9);
  });

  test('레거시 호환: 현재 stable ID는 과거 enum.index 저장값과 일치한다', () {
    // 과거에는 enum.index를 그대로 저장했다. 현재 enum 순서 기준으로
    // stable ID == index 여야 기존 작품이 올바르게 복원된다.
    for (final type in BrushType.values) {
      expect(
        type.stableId,
        type.index,
        reason:
            '$type의 stable ID가 현재 enum.index와 다르다. '
            'enum 순서를 바꿨다면 stable ID는 그대로 둬야 호환이 유지된다.',
      );
    }
  });

  test('roundtrip: stableId -> fromStableId는 원래 타입을 복원한다', () {
    for (final type in BrushType.values) {
      expect(BrushTypePersistence.fromStableId(type.stableId), type);
    }
  });

  test('알 수 없는 stable ID는 pen으로 폴백한다', () {
    expect(BrushTypePersistence.fromStableId(9999), BrushType.pen);
    expect(BrushTypePersistence.fromStableId(-1), BrushType.pen);
  });
}
