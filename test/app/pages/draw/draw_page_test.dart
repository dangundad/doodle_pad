import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets(
    'brushes and colors expose 44dp targets and selection semantics',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const _AppShell(home: DrawPage()));
      await tester.pumpAndSettle();

      final penFinder = find.byKey(const ValueKey('draw-brush-pen'));
      final blackFinder = find.byKey(const ValueKey('draw-color-000000'));

      expect(tester.getSize(penFinder).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(penFinder).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(blackFinder).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(blackFinder).width, greaterThanOrEqualTo(44));

      final penSemantics = tester.widget<Semantics>(penFinder).properties;
      final blackSemantics = tester.widget<Semantics>(blackFinder).properties;
      expect(penSemantics.button, isTrue);
      expect(penSemantics.selected, isTrue);
      expect(penSemantics.label, 'Pen');
      expect(penSemantics.onTap, isNotNull);
      expect(blackSemantics.button, isTrue);
      expect(blackSemantics.selected, isTrue);
      expect(blackSemantics.label, 'Pick a Color #000000');
      expect(blackSemantics.onTap, isNotNull);
      expect(
        tester
            .getSemantics(penFinder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .getSemantics(blackFinder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      final watercolorSemantics = tester
          .widget<Semantics>(
            find.byKey(const ValueKey('draw-brush-watercolor')),
          )
          .properties;
      expect(watercolorSemantics.hint, 'Watch an ad to unlock.');
      expect(watercolorSemantics.onTap, isNotNull);
      semanticsHandle.dispose();
    },
  );

  testWidgets('canvas colors expose selection and VoiceOver tap actions', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpWidget(const _AppShell(home: DrawPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Canvas Color'));
    await tester.pumpAndSettle();

    final whiteFinder = find.byKey(const ValueKey('canvas-color-FFFFFF'));
    final customFinder = find.byKey(const ValueKey('canvas-custom-color'));
    final whiteSemantics = tester.widget<Semantics>(whiteFinder).properties;
    final customSemantics = tester.widget<Semantics>(customFinder).properties;

    expect(tester.getSize(whiteFinder).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(whiteFinder).width, greaterThanOrEqualTo(44));
    expect(whiteSemantics.button, isTrue);
    expect(whiteSemantics.selected, isTrue);
    expect(whiteSemantics.label, 'Canvas Color #FFFFFF');
    expect(whiteSemantics.onTap, isNotNull);
    expect(customSemantics.button, isTrue);
    expect(customSemantics.selected, isFalse);
    expect(customSemantics.label, 'Pick a Color');
    expect(customSemantics.onTap, isNotNull);
    expect(
      tester
          .getSemantics(whiteFinder)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(customFinder)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    semanticsHandle.dispose();
  });

  testWidgets('draw toolbar entrances resolve immediately for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _AppShell(home: DrawPage(), disableAnimations: true),
    );
    await tester.pump();

    for (final key in const [
      ValueKey('draw-top-toolbar-entrance'),
      ValueKey('draw-bottom-toolbar-entrance'),
    ]) {
      final animation = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(key),
      );
      expect(animation.duration, Duration.zero);
    }
  });

  testWidgets('all locales fit a compact screen at 130% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final locale in Languages.supportedLocales) {
      await tester.pumpWidget(
        _AppShell(
          key: ValueKey(locale.languageCode),
          locale: locale,
          home: const DrawPage(),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} overflowed',
      );
    }
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
    // Item 7 회귀 가드: 자식 GestureDetector가 onScale*로 그리기·핀치를 함께
    // 처리하므로 InteractiveViewer 자체 제스처(pan/scale)는 모두 비활성.
    // transformController에 대한 매트릭스 적용은 컨트롤러가 직접 수행한다.
    expect(viewer.panEnabled, isFalse);
    expect(viewer.scaleEnabled, isFalse);
    expect(viewer.minScale, 0.5);
    expect(viewer.maxScale, 5.0);
  });

  testWidgets(
    'single-finger drag still records a stroke under InteractiveViewer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const _AppShell(home: DrawPage()));
      await tester.pumpAndSettle();

      expect(DoodleController.to.strokes, isEmpty);

      // 캔버스 중앙에서 한 손가락 드래그 — 회귀 가드.
      await tester.drag(find.byType(InteractiveViewer), const Offset(60, 60));
      await tester.pumpAndSettle();

      expect(DoodleController.to.strokes, isNotEmpty);
    },
  );

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
  const _AppShell({
    super.key,
    required this.home,
    this.locale = const Locale('en'),
    this.disableAnimations = false,
  });

  final Widget home;
  final Locale locale;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          translations: Languages(),
          locale: locale,
          fallbackLocale: const Locale('en'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
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
