import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;

import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/admob/ads_native.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';
import 'package:doodle_pad/app/widgets/exit_bottom_sheet.dart';

import '../helpers/fake_purchase_service.dart';

/// 종료 시트는 네이티브 고급 광고의 유일한 노출 자리다(flip_clock 과 동일).
/// 캔버스·작업 흐름에는 절대 넣지 않으므로, 이 자리가 사라지면 네이티브 지면의
/// 수익이 통째로 0이 된다.
void main() {
  setUp(() {
    Get.testMode = true;
    AdHelper.resetInitializationStateForTest();
    AdHelper.platformAdMobConfiguredOverride = true;
    Get.put<PurchaseService>(FakePurchaseService(), permanent: true);
  });

  tearDown(() {
    AdHelper.resetInitializationStateForTest();
    Get.reset();
  });

  testWidgets('종료 시트에 medium 네이티브 광고 자리가 있다', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(locale: Locale('en')));
    await tester.pumpAndSettle();

    final ad = tester.widget<NativeAdWidget>(find.byType(NativeAdWidget));
    expect(
      ad.templateType,
      TemplateType.medium,
      reason: '세로 바텀시트는 flip_clock 과 동일하게 medium 템플릿을 쓴다.',
    );
  });

  testWidgets('광고가 로드되지 않으면 여백까지 함께 접힌다', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(locale: Locale('en')));
    await tester.pumpAndSettle();

    // 단위 테스트에서는 실제 광고가 로드되지 않는다. 이때 자리와 여백이 모두
    // 0 이어야 한다 — 여백만 남으면 시트에 설명 없는 빈 공간이 생긴다.
    expect(tester.getSize(find.byType(NativeAdWidget)).height, 0);
  });

  testWidgets('시트 높이 상한은 패널 패딩 바깥에서 걸린다', (tester) async {
    const screenHeight = 568.0;
    tester.view.physicalSize = const Size(320, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(locale: Locale('en')));
    await tester.pumpAndSettle();

    // 상한이 AppPanel 안으로 들어가면 패널 패딩(40dp)과 바깥 여백이 상한에
    // 더해져, medium 광고가 실제로 로드되는 실기기에서만 시트가 화면을 넘친다.
    final caps = tester
        .widgetList<ConstrainedBox>(
          find.ancestor(
            of: find.byType(AppPanel),
            matching: find.byType(ConstrainedBox),
          ),
        )
        .map((box) => box.constraints.maxHeight)
        .where((height) => height.isFinite);

    expect(
      caps,
      contains(closeTo(screenHeight * 0.8, 1.0)),
      reason: 'AppPanel 을 감싸는 높이 상한이 없으면 광고가 로드될 때 시트가 넘친다.',
    );
  });

  testWidgets('작은 화면 + 130% 글꼴에서도 시트가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final locale in Languages.supportedLocales) {
      await tester.pumpWidget(
        _AppShell(key: ValueKey(locale.languageCode), locale: locale),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} overflowed',
      );
    }
  });
}

class _AppShell extends StatelessWidget {
  const _AppShell({super.key, required this.locale});

  final Locale locale;

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
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ExitBottomSheet(),
            ),
          ),
        );
      },
    );
  }
}
