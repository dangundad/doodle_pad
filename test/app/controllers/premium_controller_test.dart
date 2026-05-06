import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

import '../helpers/fake_purchase_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<PurchaseService>(FakePurchaseService(), permanent: true);
  });

  tearDown(Get.reset);

  test(
    'plans represent three support tiers with medium selected by default',
    () {
      final controller = PremiumController();

      expect(controller.selectedPlanIndex.value, 1);
      expect(controller.plans.length, 3);
      expect(controller.plans.map((plan) => plan.productId), [
        PurchaseConstants.PREMIUM_SMALL_ANDROID,
        PurchaseConstants.PREMIUM_MEDIUM_ANDROID,
        PurchaseConstants.PREMIUM_LARGE_ANDROID,
      ]);
      expect(controller.plans.map((plan) => plan.titleKey), [
        'premium_support_small_title',
        'premium_support_medium_title',
        'premium_support_large_title',
      ]);
    },
  );
}
