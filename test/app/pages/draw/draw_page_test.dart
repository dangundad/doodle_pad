import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
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
    await Hive.openBox(HiveService.SETTINGS_BOX);
    await Hive.openBox(HiveService.APP_DATA_BOX);

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

    expect(clearButton.onPressed, isNull);
    expect(shareButton.onPressed, isNull);
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

    await tester.tap(find.byTooltip('Back'));
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
