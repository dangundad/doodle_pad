import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/gallery_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/services/artwork_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Drawing> box;
  late ArtworkRepository repo;

  Future<void> seed(String id) => repo.save(
    id: id,
    canvasColor: 0,
    canvasLogicalSize: const ui.Size(1, 1),
    referenceImagePath: null,
    strokes: const [],
    thumbnailPngBytes: Uint8List.fromList(const [1]),
  );

  setUp(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('gallery_ctrl_test_');
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
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('onInit: 기존 작품을 리스트에 로드', () async {
    await seed('a');
    await seed('b');

    final controller = GalleryController(repository: repo);
    controller.onInit();

    expect(controller.artworks.length, 2);
  });

  test('deleteArtwork: 삭제 후 리스트 갱신', () async {
    await seed('a');
    await seed('b');
    final controller = GalleryController(repository: repo);
    controller.onInit();

    await controller.deleteArtwork('a');

    expect(controller.artworks.length, 1);
    expect(controller.artworks.first.id, 'b');
  });

  test('isAboveWarnThreshold: 100개 이하면 false', () async {
    await seed('a');
    final controller = GalleryController(repository: repo);
    controller.onInit();

    expect(controller.isAboveWarnThreshold, false);
  });
}
