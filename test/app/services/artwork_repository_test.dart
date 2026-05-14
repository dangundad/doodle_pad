import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/services/artwork_repository.dart';

SerializableStroke _stroke() => SerializableStroke(
  colorArgb: 0xFF000000,
  width: 4.0,
  isEraser: false,
  brushTypeIndex: 0,
  seed: 1,
  pointsXY: const [0, 0, 10, 10, 20, 20],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Drawing> box;
  late ArtworkRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('artwork_repo_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DrawingAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SerializableStrokeAdapter());
    }
    box = await Hive.openBox<Drawing>('drawings_test');
    repo = ArtworkRepository(
      box: box,
      supportDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save: Hive entry + 썸네일 파일이 생성된다', () async {
    final drawing = await repo.save(
      id: 'a1',
      canvasColor: 0xFFFFFFFF,
      canvasLogicalSize: const ui.Size(300, 600),
      referenceImagePath: null,
      strokes: [_stroke()],
      thumbnailPngBytes: Uint8List.fromList(const [1, 2, 3]),
    );

    expect(box.length, 1);
    expect(drawing.thumbnailPath, isNotNull);
    expect(File(drawing.thumbnailPath!).existsSync(), true);
    expect(drawing.strokes.first.pointsXY, const [0, 0, 10, 10, 20, 20]);
  });

  test('adapter roundtrip: 저장 후 다시 읽어도 필드 손실 없음', () async {
    final srcRef = File('${tempDir.path}${Platform.pathSeparator}src_ref.png');
    await srcRef.writeAsBytes(const [1, 2, 3, 4]);

    await repo.save(
      id: 'a2',
      canvasColor: 0xFF112233,
      canvasLogicalSize: const ui.Size(123, 456),
      referenceImagePath: srcRef.path,
      strokes: [_stroke()],
      thumbnailPngBytes: Uint8List.fromList(const [9]),
    );

    final loaded = repo.findById('a2');
    expect(loaded, isNotNull);
    expect(loaded!.canvasColor, 0xFF112233);
    expect(loaded.canvasLogicalWidth, 123);
    expect(loaded.canvasLogicalHeight, 456);
    // 참조 사진은 references 디렉터리 안 복사본 경로로 기록된다.
    expect(loaded.referenceImagePath, isNotNull);
    expect(
      loaded.referenceImagePath,
      contains('${Platform.pathSeparator}references${Platform.pathSeparator}'),
    );
    expect(File(loaded.referenceImagePath!).existsSync(), true);
    expect(loaded.strokes.length, 1);
    expect(loaded.strokes.first.colorArgb, 0xFF000000);
  });

  test('save: 참조 사진을 app support directory로 복사한다', () async {
    final srcRef = File('${tempDir.path}${Platform.pathSeparator}picked.jpg');
    await srcRef.writeAsBytes(const [10, 20, 30]);

    final drawing = await repo.save(
      id: 'ref1',
      canvasColor: 0xFFFFFFFF,
      canvasLogicalSize: const ui.Size(100, 100),
      referenceImagePath: srcRef.path,
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );

    // 복사본은 원본과 다른 경로이고, 원본을 지워도 살아있어야 한다.
    expect(drawing.referenceImagePath, isNot(srcRef.path));
    expect(File(drawing.referenceImagePath!).existsSync(), true);
    await srcRef.delete();
    expect(File(drawing.referenceImagePath!).existsSync(), true);
  });

  test('save: 참조 사진 원본이 이미 사라졌으면 referenceImagePath는 null', () async {
    final drawing = await repo.save(
      id: 'ref_missing',
      canvasColor: 0xFFFFFFFF,
      canvasLogicalSize: const ui.Size(100, 100),
      referenceImagePath: '${tempDir.path}${Platform.pathSeparator}nope.png',
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );

    expect(drawing.referenceImagePath, isNull);
  });

  test('delete: references 복사본도 함께 제거된다', () async {
    final srcRef = File('${tempDir.path}${Platform.pathSeparator}picked2.png');
    await srcRef.writeAsBytes(const [5, 6, 7]);

    final drawing = await repo.save(
      id: 'ref_del',
      canvasColor: 0xFFFFFFFF,
      canvasLogicalSize: const ui.Size(100, 100),
      referenceImagePath: srcRef.path,
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );
    final copiedRef = drawing.referenceImagePath!;
    expect(File(copiedRef).existsSync(), true);

    await repo.delete('ref_del');

    expect(File(copiedRef).existsSync(), false);
  });

  test('listAll: updatedAt desc 정렬', () async {
    await repo.save(
      id: 'old',
      canvasColor: 0,
      canvasLogicalSize: const ui.Size(1, 1),
      referenceImagePath: null,
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.save(
      id: 'new',
      canvasColor: 0,
      canvasLogicalSize: const ui.Size(1, 1),
      referenceImagePath: null,
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );

    final list = repo.listAll();
    expect(list.first.id, 'new');
    expect(list.last.id, 'old');
  });

  test('delete: box entry + 썸네일 파일이 함께 제거된다 (Plan FR-12)', () async {
    final drawing = await repo.save(
      id: 'del',
      canvasColor: 0,
      canvasLogicalSize: const ui.Size(1, 1),
      referenceImagePath: null,
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );
    final thumbPath = drawing.thumbnailPath!;
    expect(File(thumbPath).existsSync(), true);

    await repo.delete('del');

    expect(box.containsKey('del'), false);
    expect(File(thumbPath).existsSync(), false);
  });

  test('count: 저장 개수를 반환', () async {
    expect(repo.count(), 0);
    await repo.save(
      id: 'c1',
      canvasColor: 0,
      canvasLogicalSize: const ui.Size(1, 1),
      referenceImagePath: null,
      strokes: const [],
      thumbnailPngBytes: Uint8List.fromList(const [1]),
    );
    expect(repo.count(), 1);
  });
}
