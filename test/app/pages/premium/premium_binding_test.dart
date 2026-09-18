import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/pages/premium/premium_binding.dart';
import 'package:doodle_pad/app/pages/premium/premium_page.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';

import '../../helpers/fake_purchase_service.dart';

/// PREMIUM 라우트 의존성 회귀 테스트.
///
/// `PremiumController` 를 `AppBinding` 의 `Get.lazyPut`(fenix 아님) 하나로만
/// 등록하면, 첫 진입에서 팩토리가 소비돼 인스턴스가 되고 라우트를 닫을 때
/// (SmartManagement.full) 그 인스턴스가 정리되면서 **다시 만들 방법이 사라진다**.
/// 그래서 두 번째 진입에서 `"PremiumController" not found` 로 화면이 깨졌다.
/// 라우트가 필요로 하는 컨트롤러는 그 라우트의 바인딩이 매번 준비해야 한다.
void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<PurchaseService>(_PremiumFakePurchaseService(), permanent: true);
  });

  tearDown(Get.reset);

  test('PremiumBinding 은 인스턴스가 정리된 뒤에도 컨트롤러를 다시 준비한다', () {
    final binding = PremiumBinding();

    binding.dependencies();
    expect(Get.find<PremiumController>(), isA<PremiumController>());

    // 라우트를 닫을 때 GetX 가 하는 일.
    Get.delete<PremiumController>();

    binding.dependencies();
    expect(
      () => Get.find<PremiumController>(),
      returnsNormally,
      reason: '두 번째 진입에서도 컨트롤러를 찾을 수 있어야 한다',
    );
  });

  testWidgets('프리미엄 화면을 닫았다가 다시 열어도 예외 없이 뜬다', (tester) async {
    // 앱 시작 시 AppBinding 이 하는 등록을 그대로 흉내 낸다.
    Get.lazyPut<PremiumController>(() => PremiumController());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => GetMaterialApp(
          translations: Languages(),
          locale: const Locale('en'),
          initialRoute: '/home',
          getPages: [
            GetPage(
              name: '/home',
              page: () => const Scaffold(body: Center(child: Text('home'))),
            ),
            GetPage(
              name: '/premium',
              page: () => const PremiumPage(),
              binding: PremiumBinding(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Get.toNamed<void>('/premium');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PremiumPage), findsOneWidget);

    Get.back<void>();
    await tester.pumpAndSettle();

    Get.toNamed<void>('/premium');
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: '두 번째 진입에서 컨트롤러를 못 찾아 화면이 깨지면 안 된다',
    );
    expect(find.byType(PremiumPage), findsOneWidget);
  });
}

class _PremiumFakePurchaseService extends FakePurchaseService {
  final RxBool _isLoading = false.obs;

  @override
  RxBool get isLoading => _isLoading;

  @override
  String getProductPrice(int index, String fallback) => fallback;
}
