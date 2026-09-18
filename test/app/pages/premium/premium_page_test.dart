import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/pages/premium/premium_page.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';

import '../../helpers/fake_purchase_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<PurchaseService>(_PremiumFakePurchaseService(), permanent: true);
    Get.put<PremiumController>(PremiumController());
  });

  tearDown(() {
    AdHelper.resetInitializationStateForTest();
    Get.reset();
  });

  testWidgets('배너는 구매 바 위에 붙고, 구매 완료 후에는 사라진다', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // 테스트 호스트는 Android/iOS가 아니라 광고 슬롯이 통째로 꺼진다.
    AdHelper.platformAdMobConfiguredOverride = true;

    await tester.pumpWidget(const _AppShell(locale: Locale('en')));
    await tester.pump();

    expect(find.byType(AdBannerBar), findsOneWidget);
    expect(find.byType(BannerAdWidget), findsOneWidget);

    // 결제 CTA 바로 아래에 광고가 붙으면 오탭 위험이 커진다(AdMob 정책).
    final bannerRect = tester.getRect(find.byType(BannerAdWidget));
    final purchaseBarRect = tester.getRect(
      find.byKey(const ValueKey('premium_purchase_bar')),
    );
    expect(
      bannerRect.bottom,
      lessThanOrEqualTo(purchaseBarRect.top),
      reason: '배너는 구매 바보다 위에 있어야 한다.',
    );

    // 구매가 끝나면 구매 바와 배너가 함께 사라진다.
    PurchaseService.to.isPremium.value = true;
    await tester.pump();

    expect(find.byType(BannerAdWidget), findsNothing);
    expect(find.byKey(const ValueKey('premium_purchase_bar')), findsNothing);
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
        _AppShell(key: ValueKey(locale.languageCode), locale: locale),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} overflowed',
      );
    }
  });

  testWidgets('German plan titles keep visible spacing from prices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _AppShell(locale: Locale('de')));
    await tester.pump();

    final benefitLabel = tester.widget<Text>(
      find.text('Einmalige Unterstützung'),
    );

    final titleRect = tester.getRect(find.text('Abendessen'));
    final priceRect = tester.getRect(find.text('￦9,900'));

    expect(benefitLabel.maxLines, isNull);
    expect(priceRect.left - titleRect.right, greaterThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
  });
}

class _PremiumFakePurchaseService extends FakePurchaseService {
  final RxBool _isLoading = false.obs;

  @override
  RxBool get isLoading => _isLoading;

  @override
  String getProductPrice(int index, String fallback) => fallback;
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
      builder: (context, child) => GetMaterialApp(
        translations: Languages(),
        locale: locale,
        fallbackLocale: const Locale('en'),
        home: const PremiumPage(),
      ),
    );
  }
}
