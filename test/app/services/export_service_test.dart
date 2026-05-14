import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';

import 'package:doodle_pad/app/services/export_service.dart';

/// 작은 단색 [ui.Image]를 만든다. 인코딩 포맷 검증용.
Future<ui.Image> _solidImage(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = const Color(0xFF4080C0),
  );
  final picture = recorder.endRecording();
  return picture.toImage(size, size);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // RepaintBoundary 캡처는 위젯 환경이 필요하므로 본 단위 테스트는
  // 권한·재시도·에러 매핑 로직(@visibleForTesting putBytesForTest)만 검증한다.
  // 풀 통합은 widget test에서 별도 다룬다.

  final dummyBytes = Uint8List.fromList(const [1, 2, 3, 4]);

  test('성공: 1차 putBytes 호출이 성공하면 success', () async {
    var calls = 0;
    final service = ExportService(
      putBytes: (bytes, {String name = 'image', String? album}) async {
        calls += 1;
        expect(bytes, dummyBytes);
        expect(name, 'doodle.png');
      },
      requestAccess: () async => fail('requestAccess는 호출되지 않아야 한다'),
    );

    final result = await service.putBytesForTest(
      bytes: dummyBytes,
      fileName: 'doodle.png',
    );

    expect(result.success, true);
    expect(calls, 1);
  });

  test('권한 거부 → 요청 승인 후 재시도 → success', () async {
    var putCalls = 0;
    var accessCalls = 0;
    final service = ExportService(
      putBytes: (bytes, {String name = 'image', String? album}) async {
        putCalls += 1;
        if (putCalls == 1) {
          throw GalException(
            type: GalExceptionType.accessDenied,
            platformException: PlatformException(code: 'ACCESS_DENIED'),
            stackTrace: StackTrace.current,
          );
        }
      },
      requestAccess: () async {
        accessCalls += 1;
        return true;
      },
    );

    final result = await service.putBytesForTest(
      bytes: dummyBytes,
      fileName: 'doodle.png',
    );

    expect(result.success, true);
    expect(putCalls, 2);
    expect(accessCalls, 1);
  });

  test('권한 거부 → 요청도 거부 → permissionDenied 반환', () async {
    final service = ExportService(
      putBytes: (bytes, {String name = 'image', String? album}) async {
        throw GalException(
          type: GalExceptionType.accessDenied,
          platformException: PlatformException(code: 'ACCESS_DENIED'),
          stackTrace: StackTrace.current,
        );
      },
      requestAccess: () async => false,
    );

    final result = await service.putBytesForTest(
      bytes: dummyBytes,
      fileName: 'doodle.png',
    );

    expect(result.success, false);
    expect(result.failure, ExportFailure.permissionDenied);
  });

  test('notEnoughSpace → ioError로 매핑', () async {
    final service = ExportService(
      putBytes: (bytes, {String name = 'image', String? album}) async {
        throw GalException(
          type: GalExceptionType.notEnoughSpace,
          platformException: PlatformException(code: 'NOT_ENOUGH_SPACE'),
          stackTrace: StackTrace.current,
        );
      },
      requestAccess: () async => fail('호출되지 않아야 한다'),
    );

    final result = await service.putBytesForTest(
      bytes: dummyBytes,
      fileName: 'doodle.png',
    );

    expect(result.failure, ExportFailure.ioError);
  });

  test('알 수 없는 예외 → unexpected', () async {
    final service = ExportService(
      putBytes: (bytes, {String name = 'image', String? album}) async {
        throw StateError('boom');
      },
      requestAccess: () async => fail('호출되지 않아야 한다'),
    );

    final result = await service.putBytesForTest(
      bytes: dummyBytes,
      fileName: 'doodle.png',
    );

    expect(result.failure, ExportFailure.unexpected);
  });

  test('PNG 포맷 선택 시 PNG 시그니처 bytes를 반환한다', () async {
    final service = ExportService();
    final image = await _solidImage(8);
    final bytes = await service.encodeForTest(image, ExportImageFormat.png);
    image.dispose();

    // PNG magic: 89 50 4E 47 0D 0A 1A 0A
    expect(bytes.length, greaterThan(8));
    expect(
      bytes.sublist(0, 8),
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    );
  });

  test('JPEG 포맷 선택 시 실제 JPEG 시그니처 bytes를 반환한다', () async {
    final service = ExportService();
    final image = await _solidImage(8);
    final bytes = await service.encodeForTest(image, ExportImageFormat.jpeg);
    image.dispose();

    // JPEG SOI marker: FF D8 FF. 과거에는 .jpg 확장자에 PNG bytes가 담겼다.
    expect(bytes.length, greaterThan(3));
    expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
  });
}
