import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/pages/draw/draw_page.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vibrationChannel = MethodChannel('vibration');
  late Directory tempDir;

  setUp(() async {
    Get.testMode = true;

    tempDir = await Directory.systemTemp.createTemp(
      'doodle_pad_draw_page_test_',
    );
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DrawingAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SerializableStrokeAdapter());
    }
    await Hive.openBox(HiveService.SETTINGS_BOX);
    await Hive.openBox(HiveService.APP_DATA_BOX);
    await Hive.openBox<Drawing>(HiveService.DRAWINGS_BOX);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, (call) async {
          switch (call.method) {
            case 'hasVibrator':
              return true;
            case 'vibrate':
              return null;
            default:
              return null;
          }
        });

    Get.put<HiveService>(HiveService(), permanent: true);
    Get.put<SettingController>(_FakeSettingController(), permanent: true);
    Get.put<DoodleController>(DoodleController(), permanent: true);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, null);
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  testWidgets('top toolbar does not overflow on compact width', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('clear and share actions are disabled on an empty canvas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    final clearButton = tester.widget<IconButton>(
      _iconButtonByTooltip('Clear Canvas'),
    );
    final shareButton = tester.widget<IconButton>(
      _iconButtonByTooltip('Share'),
    );
    final saveButton = tester.widget<IconButton>(
      _iconButtonByTooltip('Save to Gallery'),
    );
    final artworkButton = tester.widget<IconButton>(
      _iconButtonByTooltip('Save as artwork'),
    );

    expect(clearButton.onPressed, isNull);
    expect(shareButton.onPressed, isNull);
    expect(saveButton.onPressed, isNull);
    expect(artworkButton.onPressed, isNull);
  });

  testWidgets('save and artwork actions are enabled when a stroke exists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    DoodleController.to.strokes.add(
      DrawingStroke(
        points: const [Offset(10, 10), Offset(20, 20)],
        color: Colors.black,
        width: 4,
      ),
    );

    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<IconButton>(
      _iconButtonByTooltip('Save to Gallery'),
    );
    final artworkButton = tester.widget<IconButton>(
      _iconButtonByTooltip('Save as artwork'),
    );

    expect(saveButton.onPressed, isNotNull);
    expect(artworkButton.onPressed, isNotNull);
  });

  testWidgets('canvas is wrapped in InteractiveViewer for pinch zoom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    // panEnabled=false라야 한 손가락 그리기가 GestureDetector로 전달된다.
    expect(viewer.panEnabled, isFalse);
    expect(viewer.scaleEnabled, isTrue);
    expect(viewer.minScale, 0.5);
    expect(viewer.maxScale, 5.0);
  });

  testWidgets('single-finger drag still records a stroke under InteractiveViewer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    expect(DoodleController.to.strokes, isEmpty);

    // 캔버스 중앙에서 한 손가락 드래그 — 회귀 가드.
    await tester.drag(
      find.byType(InteractiveViewer),
      const Offset(60, 60),
    );
    await tester.pumpAndSettle();

    expect(DoodleController.to.strokes, isNotEmpty);
  });

  testWidgets('back button asks before discarding an active drawing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    DoodleController.to.strokes.add(
      DrawingStroke(
        points: const [Offset(12, 12), Offset(24, 24)],
        color: Colors.black,
        width: 4,
      ),
    );

    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    // Item 3: DRAW의 leading은 'Home' 아이콘이지만 동일하게 discard 확인 다이얼로그를 띄운다.
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Discard drawing?'), findsOneWidget);
  });
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          translations: Languages(),
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          home: home,
        );
      },
    );
  }
}

Finder _iconButtonByTooltip(String tooltip) {
  return find.ancestor(
    of: find.byTooltip(tooltip),
    matching: find.byType(IconButton),
  );
}

class _FakeSettingController extends SettingController {
  _FakeSettingController() : super(loadOnInit: false, updateLocaleFn: _noop);

  static Future<void> _noop(Locale _) async {}
}
