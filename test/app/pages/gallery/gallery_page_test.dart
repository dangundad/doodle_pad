import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/gallery_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/pages/gallery/gallery_page.dart';
import 'package:doodle_pad/app/services/artwork_repository.dart';
import 'package:doodle_pad/app/translate/translate.dart';

Widget _shell(Widget home) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => GetMaterialApp(
      translations: Languages(),
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Drawing> box;
  late ArtworkRepository repo;

  Future<void> seed(String id) => repo.save(
    id: id,
    canvasColor: 0xFFFFFFFF,
    canvasLogicalSize: const ui.Size(300, 600),
    referenceImagePath: null,
    strokes: const [],
    thumbnailPngBytes: Uint8List.fromList(const [1, 2, 3]),
  );

  setUp(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('gallery_page_test_');
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

  testWidgets('빈 작품함: 빈 상태 위젯과 안내 문구를 보여준다', (tester) async {
    Get.put<GalleryController>(GalleryController(repository: repo));

    await tester.pumpWidget(_shell(const GalleryPage()));
    await tester.pumpAndSettle();

    expect(find.text('No artworks yet'), findsOneWidget);
    expect(find.text('Start Drawing'), findsOneWidget);
  });

  testWidgets('작품이 있으면 그리드와 작품 수를 표시한다', (tester) async {
    await seed('a');
    await seed('b');
    Get.put<GalleryController>(GalleryController(repository: repo));

    await tester.pumpWidget(_shell(const GalleryPage()));
    // GridView 안의 Image.file 디코딩 때문에 pumpAndSettle은 멈추지 않으므로
    // 명시적 pump으로 빌드만 완료시킨다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // AppBar 타이틀에 개수 표시
    expect(find.textContaining('My Artworks (2)'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    // 빈 상태 위젯은 없어야 함
    expect(find.text('No artworks yet'), findsNothing);

    // Image.file의 pending 디코딩이 테스트 종료를 막지 않도록 트리를 비운다.
    await tester.pumpWidget(const SizedBox());
  });
}
