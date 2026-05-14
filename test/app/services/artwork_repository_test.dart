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
    await repo.save(
      id: 'a2',
      canvasColor: 0xFF112233,
      canvasLogicalSize: const ui.Size(123, 456),
      referenceImagePath: '/some/ref.png',
      strokes: [_stroke()],
      thumbnailPngBytes: Uint8List.fromList(const [9]),
    );

    final loaded = repo.findById('a2');
    expect(loaded, isNotNull);
    expect(loaded!.canvasColor, 0xFF112233);
    expect(loaded.canvasLogicalWidth, 123);
    expect(loaded.canvasLogicalHeight, 456);
    expect(loaded.referenceImagePath, '/some/ref.png');
    expect(loaded.strokes.length, 1);
    expect(loaded.strokes.first.colorArgb, 0xFF000000);
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
