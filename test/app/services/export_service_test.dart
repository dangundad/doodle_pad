import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';

import 'package:doodle_pad/app/services/export_service.dart';

void main() {
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
}
