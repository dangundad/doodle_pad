import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:doodle_pad/app/data/models/drawing.dart';

/// 작품 영속화 책임.
/// Design Ref: §4.2 — Hive `drawings` box + 디스크 썸네일 IO.
/// 외부 위젯/컨트롤러는 이 인터페이스만 사용. Hive·File 직접 접근 금지.
class ArtworkRepository {
  ArtworkRepository({
    Box<Drawing>? box,
    Future<Directory> Function()? supportDirProvider,
  }) : _boxOverride = box,
       _supportDirProvider =
           supportDirProvider ?? getApplicationSupportDirectory;

  /// 프로덕션 싱글톤. 테스트는 새 인스턴스를 만들어 box·디렉터리를 주입한다.
  static final ArtworkRepository instance = ArtworkRepository();

  final Box<Drawing>? _boxOverride;
  final Future<Directory> Function() _supportDirProvider;

  static const String _thumbnailsDir = 'thumbnails';
  static const String _referencesDir = 'references';
  static const String _drawingsBoxName = 'drawings';

  Box<Drawing> get _box {
    return _boxOverride ?? Hive.box<Drawing>(_drawingsBoxName);
  }

  Future<Directory> _ensureThumbnailDir() async {
    final root = await _supportDirProvider();
    final dir = Directory('${root.path}${Platform.pathSeparator}$_thumbnailsDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _ensureReferenceDir() async {
    final root = await _supportDirProvider();
    final dir = Directory('${root.path}${Platform.pathSeparator}$_referencesDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 경로에서 확장자(`.`포함)를 추출한다. 디렉터리 구분자 뒤의 마지막 `.`만 인정.
  /// 비정상적으로 긴 토큰은 확장자로 보지 않는다.
  String _extensionOf(String path) {
    final sepIdx = path.lastIndexOf(Platform.pathSeparator);
    final dotIdx = path.lastIndexOf('.');
    if (dotIdx <= sepIdx || dotIdx < 0) return '';
    final ext = path.substring(dotIdx);
    return ext.length <= 6 ? ext.toLowerCase() : '';
  }

  /// 작품의 참조 사진을 app support directory로 복사한다.
  ///
  /// image_picker가 돌려주는 경로는 OS 캐시라 정리/삭제될 수 있어,
  /// 작품을 다시 열 때 배경 사진이 사라지는 회귀를 막기 위해 영속 복사한다.
  /// 원본이 이미 사라졌거나 복사에 실패하면 null을 반환한다 (stroke만 보존).
  Future<String?> _persistReferenceImage(String id, String? srcPath) async {
    if (srcPath == null) return null;
    try {
      final src = File(srcPath);
      if (!await src.exists()) return null;
      final dir = await _ensureReferenceDir();
      final dest = File(
        '${dir.path}${Platform.pathSeparator}$id${_extensionOf(srcPath)}',
      );
      // 이미 references 디렉터리 안의 파일이면(=재저장 경로 동일) 복사 불필요.
      if (src.path == dest.path) return dest.path;
      await src.copy(dest.path);
      return dest.path;
    } catch (_) {
      // 참조 사진 복사 실패가 작품 저장 자체를 막지 않도록 한다.
      return null;
    }
  }

  /// 작품을 새로 저장한다. 호출자가 이미 만든 PNG bytes를 받아 디스크에 쓴 뒤
  /// 그 경로를 `Drawing.thumbnailPath`에 기록한다.
  /// Design Ref: §4.2 — strokes 직렬화는 호출 측에서 완료된 리스트를 받는다.
  Future<Drawing> save({
    required String id,
    required int canvasColor,
    required ui.Size canvasLogicalSize,
    required String? referenceImagePath,
    required List<SerializableStroke> strokes,
    required Uint8List thumbnailPngBytes,
    String? name,
  }) async {
    final dir = await _ensureThumbnailDir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}$id.png',
    );
    await file.writeAsBytes(thumbnailPngBytes, flush: true);

    // 참조 사진을 영속 복사하고, 복사된 경로를 Drawing에 기록한다.
    final persistedRefPath = await _persistReferenceImage(
      id,
      referenceImagePath,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    final drawing = Drawing(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: name,
      canvasColor: canvasColor,
      canvasLogicalWidth: canvasLogicalSize.width,
      canvasLogicalHeight: canvasLogicalSize.height,
      referenceImagePath: persistedRefPath,
      strokes: strokes,
      thumbnailPath: file.path,
    );

    await _box.put(id, drawing);
    return drawing;
  }

  /// 최신순(updatedAt desc) 정렬된 작품 리스트.
  List<Drawing> listAll() {
    final all = _box.values.toList();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  Drawing? findById(String id) => _box.get(id);

  /// 작품 1건을 삭제하고 thumbnail·참조 사진 파일도 함께 제거한다.
  /// Plan FR-12 — 디스크 leak 방지.
  Future<void> delete(String id) async {
    final drawing = _box.get(id);
    final thumb = drawing?.thumbnailPath;
    if (thumb != null) {
      try {
        final file = File(thumb);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // 썸네일 삭제 실패는 box entry 삭제를 막지 않는다 — 다음 정리에서 self-heal.
        debugPrint('[ArtworkRepository] thumbnail delete failed: $e');
      }
    }

    // 참조 사진은 app support의 references 디렉터리 안에 있는 복사본만 삭제한다.
    // 레거시 데이터가 원본 OS 경로를 가리킬 수 있어 사용자 원본 사진은 건드리지 않는다.
    final ref = drawing?.referenceImagePath;
    if (ref != null) {
      try {
        final refDir = await _ensureReferenceDir();
        if (File(ref).parent.path == refDir.path && await File(ref).exists()) {
          await File(ref).delete();
        }
      } catch (e) {
        debugPrint('[ArtworkRepository] reference delete failed: $e');
      }
    }

    await _box.delete(id);
  }

  int count() => _box.length;
}
