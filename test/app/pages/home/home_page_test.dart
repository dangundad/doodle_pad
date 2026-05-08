import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/pages/home/home_page.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';
import 'package:doodle_pad/app/widgets/exit_bottom_sheet.dart';

import '../../helpers/fake_purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vibrationChannel = MethodChannel('vibration');

  late Directory tempDir;

  setUp(() async {
    Get.testMode = true;

    tempDir = await Directory.systemTemp.createTemp('doodle_pad_home_page_test_');
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
    Get.put<SettingController>(
      _FakeSettingController(),
      permanent: true,
    );
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

  testWidgets('hides banner ad when premium is active', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put<PurchaseService>(
      FakePurchaseService()..isPremium.value = true,
      permanent: true,
    );

    await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
    await tester.pump();

    expect(find.byType(BannerAdWidget), findsNothing);
  });

  testWidgets('shows banner ad when premium is inactive', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put<PurchaseService>(
      FakePurchaseService(),
      permanent: true,
    );

    await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
    await tester.pump();

    expect(find.byType(BannerAdWidget), findsOneWidget);
  });

  testWidgets('settings icon navigates to /settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put<PurchaseService>(FakePurchaseService(), permanent: true);

    await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
    await tester.pump();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.SETTINGS);
  });

  testWidgets('premium icon navigates to /premium', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put<PurchaseService>(FakePurchaseService(), permanent: true);

    await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
    await tester.pump();

    await tester.tap(find.byTooltip('Premium'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, Routes.PREMIUM);
  });

  testWidgets(
    'start drawing CTA on empty canvas navigates to /draw without dialog',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.put<PurchaseService>(FakePurchaseService(), permanent: true);

      await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
      await tester.pump();

      await tester.tap(find.text('Start Drawing'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.DRAW);
    },
  );

  testWidgets(
    'start drawing CTA prompts continue/start-new when drawing exists',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.put<PurchaseService>(FakePurchaseService(), permanent: true);

      final doodle = DoodleController.to;
      doodle.referenceImagePath.value = 'C:\\temp\\reference.png';

      await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
      await tester.pump();

      await tester.tap(find.text('Start Drawing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Continue your drawing?'), findsOneWidget);

      await tester.tap(find.text('Start new'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.DRAW);
      expect(doodle.referenceImagePath.value, isNull);
    },
  );

  testWidgets(
    'start drawing CTA continue option keeps the existing reference image',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.put<PurchaseService>(FakePurchaseService(), permanent: true);

      final doodle = DoodleController.to;
      doodle.referenceImagePath.value = 'C:\\temp\\reference.png';

      await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
      await tester.pump();

      await tester.tap(find.text('Start Drawing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.DRAW);
      expect(doodle.referenceImagePath.value, 'C:\\temp\\reference.png');
    },
  );

  testWidgets('system back gesture opens ExitBottomSheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put<PurchaseService>(
      FakePurchaseService()..isPremium.value = true,
      permanent: true,
    );

    await tester.pumpWidget(_buildApp(initialRoute: Routes.HOME));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ExitBottomSheet), findsOneWidget);

    Get.back();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  });
}

Widget _buildApp({required String initialRoute}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      return GetMaterialApp(
        translations: Languages(),
        locale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        initialRoute: initialRoute,
        getPages: [
          GetPage(name: Routes.HOME, page: () => const HomePage()),
          GetPage(name: Routes.SETTINGS, page: () => const _StubPage('settings')),
          GetPage(name: Routes.PREMIUM, page: () => const _StubPage('premium')),
          GetPage(name: Routes.DRAW, page: () => const _StubPage('draw')),
        ],
      );
    },
  );
}

class _StubPage extends StatelessWidget {
  final String label;
  const _StubPage(this.label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('stub-$label')));
  }
}

class _FakeSettingController extends SettingController {
  _FakeSettingController() : super(loadOnInit: false, updateLocaleFn: _noop);

  static Future<void> _noop(Locale _) async {}
}
