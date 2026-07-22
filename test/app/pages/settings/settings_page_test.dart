// ignore_for_file: must_call_super

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/pages/settings/settings_page.dart';
import 'package:doodle_pad/app/translate/translate.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('support tiles delegate to the setting controller', (
    tester,
  ) async {
    Get.put<SettingController>(_FakeSettingController());

    await tester.pumpWidget(
      const _AppShell(locale: Locale('en'), home: SettingsPage()),
    );
    await tester.pumpAndSettle();

    final rateAppTile = find.byKey(const ValueKey('settings-rate-app-tile'));
    final sendFeedbackTile = find.byKey(
      const ValueKey('settings-send-feedback-tile'),
    );
    final moreAppsTile = find.byKey(const ValueKey('settings-more-apps-tile'));
    final privacyPolicyTile = find.byKey(
      const ValueKey('settings-privacy-policy-tile'),
    );

    await tester.scrollUntilVisible(
      privacyPolicyTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(rateAppTile);
    await tester.pumpAndSettle();
    await tester.tap(sendFeedbackTile);
    await tester.pumpAndSettle();
    await tester.tap(moreAppsTile);
    await tester.pumpAndSettle();
    await tester.tap(privacyPolicyTile);
    await tester.pumpAndSettle();

    final controller = Get.find<SettingController>() as _FakeSettingController;
    expect(controller.rateAppCallCount, 1);
    expect(controller.sendFeedbackCallCount, 1);
    expect(controller.openMoreAppsCallCount, 1);
    expect(controller.openPrivacyPolicyCallCount, 1);
  });

  testWidgets(
    'clear data fallback copy does not mention removed usage history',
    (tester) async {
      Get.put<SettingController>(_FakeSettingController());

      await tester.pumpWidget(
        const _AppShell(
          locale: Locale('en'),
          home: SettingsPage(),
          includeTranslations: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Reset app preferences'), findsOneWidget);
      expect(find.textContaining('usage history'), findsNothing);
    },
  );

  testWidgets(
    'clear data confirm dialog fallback omits removed usage logs copy',
    (tester) async {
      Get.put<SettingController>(_FakeSettingController());

      await tester.pumpWidget(
        const _AppShell(
          locale: Locale('en'),
          home: SettingsPage(),
          includeTranslations: false,
        ),
      );
      await tester.pumpAndSettle();

      final clearTile = find.text('Clear local data');
      await tester.scrollUntilVisible(
        clearTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(clearTile);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('This will reset local preferences. Continue?'),
        findsOneWidget,
      );
      expect(find.textContaining('usage logs'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('all locales fit a compact screen at 130% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final locale in Languages.supportedLocales) {
      Get.reset();
      Get.testMode = true;
      Get.put<SettingController>(_FakeSettingController());

      await tester.pumpWidget(
        _AppShell(
          key: ValueKey(locale.languageCode),
          locale: locale,
          home: const SettingsPage(),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} overflowed above the fold',
      );

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1800));
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} overflowed below the fold',
      );
    }
  });

  testWidgets('Korean shake guidance preserves the complete message', (
    tester,
  ) async {
    Get.put<SettingController>(_FakeSettingController());

    await tester.pumpWidget(
      const _AppShell(locale: Locale('ko'), home: SettingsPage()),
    );
    await tester.pumpAndSettle();

    const guidance = '기기를 흔들면 캔버스를 지워요.\n지우기 전\u2060에 다시 확인해요.';
    final guidanceFinder = find.text(guidance);
    expect(guidanceFinder, findsOneWidget);

    final guidanceText = tester.widget<Text>(guidanceFinder);
    expect(guidanceText.maxLines, isNull);
    expect(guidanceText.overflow, isNull);
  });
}

class _AppShell extends StatelessWidget {
  const _AppShell({
    super.key,
    required this.home,
    required this.locale,
    this.includeTranslations = true,
  });

  final Widget home;
  final Locale locale;
  final bool includeTranslations;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          translations: includeTranslations ? Languages() : null,
          locale: locale,
          home: home,
        );
      },
    );
  }
}

class _FakeSettingController extends SettingController {
  _FakeSettingController() : super(loadOnInit: false);

  int rateAppCallCount = 0;
  int sendFeedbackCallCount = 0;
  int openMoreAppsCallCount = 0;
  int openPrivacyPolicyCallCount = 0;

  @override
  Future<void> rateApp() async {
    rateAppCallCount += 1;
  }

  @override
  Future<void> sendFeedback() async {
    sendFeedbackCallCount += 1;
  }

  @override
  Future<void> openMoreApps() async {
    openMoreAppsCallCount += 1;
  }

  @override
  Future<void> openPrivacyPolicy() async {
    openPrivacyPolicyCallCount += 1;
  }
}
