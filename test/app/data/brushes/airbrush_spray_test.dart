import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';

const int _canvasSize = 200;

/// [points] 를 에어브러시로 그린 뒤 픽셀 알파 맵을 돌려준다.
Future<ByteData> _renderAirbrush(List<Offset> points, {double width = 20}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    const Rect.fromLTWH(0, 0, _canvasSize * 1.0, _canvasSize * 1.0),
  );

  BrushPresets.of(BrushType.airbrush).render(
    canvas,
    DrawingStroke(
      points: points,
      color: const Color(0xFF000000),
      width: width,
      brushType: BrushType.airbrush,
      seed: 12345, // 결정적 패턴
    ),
  );

  final image = await recorder.endRecording().toImage(_canvasSize, _canvasSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!;
}

/// (x, y) 를 중심으로 한 [radius] 정사각 영역에서 칠해진 픽셀 수.
int _inkNear(ByteData bytes, int x, int y, {int radius = 6}) {
  var count = 0;
  for (var dy = -radius; dy <= radius; dy++) {
    for (var dx = -radius; dx <= radius; dx++) {
      final px = x + dx;
      final py = y + dy;
      if (px < 0 || py < 0 || px >= _canvasSize || py >= _canvasSize) continue;
      final alpha = bytes.getUint8((py * _canvasSize + px) * 4 + 3);
      if (alpha > 0) count++;
    }
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('에어브러시 스프레이', () {
    test('멀리 떨어진 두 입력점 사이를 보간해 끊김 없이 채운다', () async {
      // 터치 샘플링 주기 탓에 실제로 자주 생기는 간격(160px 점프).
      // 예전에는 입력점 위치에만 뿌려서 그 사이가 완전히 비었다.
      final bytes = await _renderAirbrush(const [
        Offset(20, 100),
        Offset(180, 100),
      ]);

      // 양 끝에는 당연히 잉크가 있어야 한다.
      expect(_inkNear(bytes, 20, 100), greaterThan(0));
      expect(_inkNear(bytes, 180, 100), greaterThan(0));

      // 핵심: 사이 구간이 비어 있으면 안 된다.
      for (final x in [50, 80, 100, 130, 160]) {
        expect(
          _inkNear(bytes, x, 100),
          greaterThan(0),
          reason: 'x=$x 구간이 비어 있습니다 (스프레이가 끊김).',
        );
      }
    });

    test('입력점 한 개도 그려진다', () async {
      final bytes = await _renderAirbrush(const [Offset(100, 100)]);
      expect(_inkNear(bytes, 100, 100), greaterThan(0));
    });

    test('같은 seed 는 같은 결과를 낸다 (repaint 시 깜빡임 방지)', () async {
      const points = [Offset(40, 60), Offset(120, 140)];
      final first = await _renderAirbrush(points);
      final second = await _renderAirbrush(points);
      expect(first.buffer.asUint8List(), second.buffer.asUint8List());
    });

    test('획을 이어 그려도 앞부분 패턴이 유지된다', () async {
      // 스트로크 진행 중 포인트가 추가되면, 이미 그려진 앞부분이 바뀌면 안 된다.
      final partial = await _renderAirbrush(const [
        Offset(20, 100),
        Offset(100, 100),
      ]);
      final extended = await _renderAirbrush(const [
        Offset(20, 100),
        Offset(100, 100),
        Offset(180, 100),
      ]);

      // 앞 절반 영역의 픽셀은 동일해야 한다.
      final a = partial.buffer.asUint8List();
      final b = extended.buffer.asUint8List();
      for (var y = 80; y < 120; y++) {
        for (var x = 0; x < 90; x++) {
          final i = (y * _canvasSize + x) * 4 + 3;
          expect(a[i], b[i], reason: '($x, $y) 의 앞부분 패턴이 달라졌습니다.');
        }
      }
    });
  });
}
