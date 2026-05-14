import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;

/// 갤러리 저장 출력 포맷.
/// Design Ref: §4.1 — 사용자가 시트에서 선택한 PNG/JPEG.
enum ExportImageFormat { png, jpeg }

/// 갤러리 저장 결과 분류.
/// Design Ref: §4.1 — UX 분기(toast 종류)와 1:1 매핑.
enum ExportFailure {
  noContent, // hasDrawableContent == false
  permissionDenied, // gal accessDenied
  encoderError, // ui.Image → bytes 인코딩 실패
  ioError, // gal 일반 IO 실패
  unexpected, // 그 외 예외
}

class ExportResult {
  const ExportResult.success() : success = true, failure = null;
  const ExportResult.failed(ExportFailure this.failure) : success = false;

  final bool success;
  final ExportFailure? failure;
}

/// gal 호출을 추상화해 단위 테스트에서 fake로 교체할 수 있게 한다.
/// gal 2.3.x: name은 non-nullable (default 'image').
typedef GalPutBytesFn =
    Future<void> Function(Uint8List bytes, {String name, String? album});
typedef GalRequestAccessFn = Future<bool> Function();

Future<void> _defaultPutBytes(
  Uint8List bytes, {
  String name = 'image',
  String? album,
}) {
  return Gal.putImageBytes(bytes, name: name, album: album);
}

Future<bool> _defaultRequestAccess() => Gal.requestAccess();

/// 캔버스 캡처 → 인코딩 → 갤러리 저장을 책임지는 stateless service.
/// Design Ref: §4.1 — Option C에서 외부 IO만 Service로 분리.
class ExportService {
  ExportService({
    GalPutBytesFn? putBytes,
    GalRequestAccessFn? requestAccess,
    String? defaultAlbumName,
  }) : _putBytes = putBytes ?? _defaultPutBytes,
       _requestAccess = requestAccess ?? _defaultRequestAccess,
       _albumName = defaultAlbumName;

  /// 프로덕션에서 사용하는 싱글톤. 테스트는 신규 인스턴스를 만들어 주입한다.
  static final ExportService instance = ExportService();

  final GalPutBytesFn _putBytes;
  final GalRequestAccessFn _requestAccess;
  final String? _albumName;

  /// [canvasKey]가 가리키는 RepaintBoundary를 캡처해 갤러리에 저장한다.
  ///
  /// [resolutionMultiplier]는 1/2/3만 허용. 그 외 값은 2로 정규화.
  /// 권한 거부, 인코딩 실패, IO 실패는 [ExportResult.failure]로 구분 반환한다.
  Future<ExportResult> saveCanvasToGallery({
    required GlobalKey canvasKey,
    required int resolutionMultiplier,
    required ExportImageFormat format,
    String? fileName,
  }) async {
    final ratio = _normalizeRatio(resolutionMultiplier);

    final image = await _captureBoundary(canvasKey, ratio);
    if (image == null) {
      return const ExportResult.failed(ExportFailure.noContent);
    }

    Uint8List bytes;
    try {
      bytes = await _encode(image, format);
    } catch (_) {
      image.dispose();
      return const ExportResult.failed(ExportFailure.encoderError);
    }
    image.dispose();

    return _putWithPermission(
      bytes: bytes,
      fileName: fileName ?? _defaultFileName(format),
    );
  }

  /// 권한 처리/재시도 로직 단독 검증용 seam.
  /// 실제 RepaintBoundary 캡처가 위젯 트리에 의존하므로,
  /// IO/권한 분기는 이 메서드를 직접 호출해 fake gal로 검증한다.
  @visibleForTesting
  Future<ExportResult> putBytesForTest({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _putWithPermission(bytes: bytes, fileName: fileName);
  }

  Future<ExportResult> _putWithPermission({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      await _putBytes(bytes, name: fileName, album: _albumName);
      return const ExportResult.success();
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) {
        // 한 번 권한 요청 후 재시도. 사용자가 거부하면 실패로 종결.
        final granted = await _requestAccess();
        if (!granted) {
          return const ExportResult.failed(ExportFailure.permissionDenied);
        }
        try {
          await _putBytes(bytes, name: fileName, album: _albumName);
          return const ExportResult.success();
        } on GalException catch (retry) {
          return ExportResult.failed(_mapGalException(retry));
        } catch (_) {
          return const ExportResult.failed(ExportFailure.unexpected);
        }
      }
      return ExportResult.failed(_mapGalException(e));
    } catch (_) {
      return const ExportResult.failed(ExportFailure.unexpected);
    }
  }

  Future<ui.Image?> _captureBoundary(GlobalKey key, double ratio) async {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return boundary.toImage(pixelRatio: ratio);
  }

  /// JPEG 인코딩 품질(0~100). 화질과 용량의 균형점으로 92를 사용한다.
  static const int _jpegQuality = 92;

  /// 인코딩 로직 단독 검증용 seam.
  /// RepaintBoundary 캡처는 위젯 트리에 의존하므로, 포맷별 인코딩 결과는
  /// 작은 [ui.Image]를 직접 만들어 이 메서드로 검증한다.
  @visibleForTesting
  Future<Uint8List> encodeForTest(ui.Image image, ExportImageFormat format) {
    return _encode(image, format);
  }

  Future<Uint8List> _encode(ui.Image image, ExportImageFormat format) async {
    if (format == ExportImageFormat.png) {
      // PNG는 Flutter 내장 인코더 사용.
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('toByteData returned null');
      }
      return byteData.buffer.asUint8List();
    }

    // JPEG는 ui.ImageByteFormat에 없으므로 raw RGBA를 image 패키지로 재인코딩한다.
    // 과거에는 PNG bytes를 .jpg 확장자로만 저장해 실제로는 PNG 파일이었다.
    final rawRgba = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rawRgba == null) {
      throw StateError('toByteData returned null');
    }
    final decoded = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rawRgba.buffer,
      numChannels: 4,
    );
    return img.encodeJpg(decoded, quality: _jpegQuality);
  }

  double _normalizeRatio(int multiplier) {
    if (multiplier == 1 || multiplier == 2 || multiplier == 3) {
      return multiplier.toDouble();
    }
    return 2.0;
  }

  String _defaultFileName(ExportImageFormat format) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = format == ExportImageFormat.jpeg ? 'jpg' : 'png';
    return 'doodle_$ts.$ext';
  }

  ExportFailure _mapGalException(GalException e) {
    switch (e.type) {
      case GalExceptionType.accessDenied:
        return ExportFailure.permissionDenied;
      case GalExceptionType.notEnoughSpace:
        return ExportFailure.ioError;
      case GalExceptionType.notSupportedFormat:
        return ExportFailure.encoderError;
      case GalExceptionType.unexpected:
        return ExportFailure.unexpected;
    }
  }
}
