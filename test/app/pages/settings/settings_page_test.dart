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
      const _AppShell(
        locale: Locale('en'),
        home: SettingsPage(),
      ),
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
