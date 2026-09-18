// ignore_for_file: must_call_super

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/pages/settings/settings_page.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

import '../../helpers/fake_purchase_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    AdHelper.resetInitializationStateForTest();
    Get.reset();
  });

  testWidgets('설정 하단에 배너 슬롯이 붙는다', (tester) async {
    Get.put<SettingController>(_FakeSettingController());
    AdHelper.platformAdMobConfiguredOverride = true;
    Get.put<PurchaseService>(FakePurchaseService(), permanent: true);

    await tester.pumpWidget(
      const _AppShell(locale: Locale('en'), home: SettingsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdBannerBar), findsOneWidget);
    expect(find.byType(BannerAdWidget), findsOneWidget);
  });

  testWidgets('광고 개인정보 옵션 행은 UMP가 요구할 때만 나타난다', (tester) async {
    Get.put<SettingController>(_FakeSettingController());
    final tile = find.byKey(const ValueKey('settings-privacy-choices-tile'));

    // 동의 폼이 필요 없는 지역(대부분의 국가) — 행을 노출하지 않는다.
    AdHelper.privacyOptionsRequired.value = false;
    await tester.pumpWidget(
      const _AppShell(locale: Locale('en'), home: SettingsPage()),
    );
    await tester.pumpAndSettle();
    expect(tile, findsNothing);

    // EEA/UK 처럼 동의를 다시 바꿀 경로가 필요한 지역 — 행이 나타난다.
    AdHelper.privacyOptionsRequired.value = true;
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tile, findsOneWidget);
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
    final moreAppsTile = find.byKey(const ValueKey('settings-more-apps-tile'));

    await tester.scrollUntilVisible(
      moreAppsTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(rateAppTile);
    await tester.pumpAndSettle();
    await tester.tap(moreAppsTile);
    await tester.pumpAndSettle();

    final controller = Get.find<SettingController>() as _FakeSettingController;
    expect(controller.rateAppCallCount, 1);
    expect(controller.openMoreAppsCallCount, 1);
  });

  testWidgets('목록 마지막 행은 앱 버전을 보여 준다', (tester) async {
    Get.put<SettingController>(_FakeSettingController());

    await tester.pumpWidget(
      const _AppShell(locale: Locale('en'), home: SettingsPage()),
    );
    await tester.pumpAndSettle();

    final versionTile = find.byKey(
      const ValueKey('settings-app-version-tile'),
    );
    await tester.scrollUntilVisible(
      versionTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('1.2.3 (45)'), findsOneWidget);
    // 개인정보 처리방침 행은 더 이상 없다.
    expect(
      find.byKey(const ValueKey('settings-privacy-policy-tile')),
      findsNothing,
    );
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

      expect(find.byType(AppConfirmDialog), findsOneWidget);
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

  testWidgets(
    'language row shows only the current language and opens a dropdown',
    (tester) async {
      final controller = _FakeSettingController();
      Get.put<SettingController>(controller);

      await tester.pumpWidget(
        const _AppShell(locale: Locale('en'), home: SettingsPage()),
      );
      await tester.pumpAndSettle();

      final languageTile = find.byKey(const ValueKey('settings-language-tile'));
      await tester.scrollUntilVisible(
        languageTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // 접힌 상태에서는 현재 언어만 노출한다(예전 칩 목록 회귀 방지).
      expect(find.text('English'), findsOneWidget);
      expect(find.text('한국어'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);

      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // 드롭다운에는 지원 언어가 모두 들어 있다.
      for (final label in SettingsPage.languageOptionsForTest.values) {
        expect(
          find.text(label),
          findsWidgets,
          reason: '$label is missing from the language menu',
        );
      }

      await tester.tap(find.text('한국어').last);
      await tester.pumpAndSettle();

      expect(controller.languageCalls, <String>['ko']);
      // 선택 후에는 요약 줄이 새 언어를 보여 준다.
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('English'), findsNothing);
    },
  );

  testWidgets('Korean shake guidance preserves the complete message', (
    tester,
  ) async {
    Get.put<SettingController>(_FakeSettingController());

    await tester.pumpWidget(
      const _AppShell(locale: Locale('ko'), home: SettingsPage()),
    );
    await tester.pumpAndSettle();

    // 한 줄로 짧게 다듬은 안내 문구 (줄바꿈/word-joiner 하드코딩 제거).
    // 잘림 없이 전체가 렌더링되는지 계속 고정한다.
    const guidance = '흔들면 확인 후 지워요';
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
  _FakeSettingController() : super(loadOnInit: false, packageInfoFn: _fakeInfo);

  /// 테스트 호스트에는 package_info_plus 플랫폼 구현이 없으므로 값을 주입한다.
  static Future<PackageInfo> _fakeInfo() async => PackageInfo(
    appName: 'Doodle Pad',
    packageName: 'com.dangundad.doodlepad',
    version: '1.2.3',
    buildNumber: '45',
  );

  final List<String> languageCalls = <String>[];
  int rateAppCallCount = 0;
  int openMoreAppsCallCount = 0;

  /// 실제 구현은 Hive 에 쓴다. `testWidgets` 안에서 Hive 쓰기가 발생하면
  /// FakeAsync 에 묶여 완료되지 않으므로 호출만 기록한다.
  @override
  Future<void> setLanguage(String value) async {
    languageCalls.add(value);
    language.value = value;
  }

  @override
  Future<void> rateApp() async {
    rateAppCallCount += 1;
  }

  @override
  Future<void> openMoreApps() async {
    openMoreAppsCallCount += 1;
  }
}
