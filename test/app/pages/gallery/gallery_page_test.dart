import 'dart:io';

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

  /// thumbnailPath=null인 Drawing을 box에 넣는다.
  /// - thumbnailPath null로 두어 `_ThumbnailView`가 `Image.file`을 거치지 않게 하고,
  ///   실제 디스크 디코딩 hang을 피한다.
  /// - `box.put`은 dart:io 디스크 쓰기라 `testWidgets`의 FakeAsync 존에서는
  ///   완료되지 않으므로, 호출 측에서 반드시 `tester.runAsync`로 감싸 호출한다.
  Future<void> seed(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await box.put(
      id,
      Drawing(
        id: id,
        createdAt: now,
        updatedAt: now,
        canvasColor: 0xFFFFFFFF,
        canvasLogicalWidth: 300,
        canvasLogicalHeight: 600,
        strokes: const [],
      ),
    );
  }

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
    await tester.pump();
    await tester.pump();

    expect(find.text('No artworks yet'), findsOneWidget);
    expect(find.text('Start Drawing'), findsOneWidget);
  });

  testWidgets('작품이 있으면 그리드와 작품 수를 표시한다', (tester) async {
    // Hive `box.put`은 실제 dart:io 쓰기라 FakeAsync에서 완료되지 않는다.
    // `runAsync`로 real async 존에서 시딩해 hang을 회피한다.
    await tester.runAsync(() async {
      await seed('a');
      await seed('b');
    });
    Get.put<GalleryController>(GalleryController(repository: repo));

    await tester.pumpWidget(_shell(const GalleryPage()));
    await tester.pump();
    await tester.pump();

    // AppBar 타이틀에 개수 표시
    expect(find.textContaining('My Artworks (2)'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    // 빈 상태 위젯은 없어야 함
    expect(find.text('No artworks yet'), findsNothing);
  });
}
