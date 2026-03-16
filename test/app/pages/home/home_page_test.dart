// ignore_for_file: must_call_super

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/pages/home/home_page.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vibrationChannel = MethodChannel('vibration');

  late Directory tempDir;

  setUp(() async {
    Get.testMode = true;

    tempDir = await Directory.systemTemp.createTemp(
      'doodle_pad_home_page_test_',
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

  testWidgets(
    'does not show onboarding dialog when brush guide setting is disabled',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = _FakeSettingController()
        ..isFirstRun.value = true
        ..showBrushGuide.value = false;
      Get.put<SettingController>(controller);

      await tester.pumpWidget(
        const _AppShell(
          locale: Locale('en'),
          home: HomeContentPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Welcome'), findsNothing);
    },
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.home,
    required this.locale,
  });

  final Widget home;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          translations: Languages(),
          locale: locale,
          home: home,
        );
      },
    );
  }
}

class _FakeSettingController extends SettingController {
  _FakeSettingController() : super(loadOnInit: false);
}
