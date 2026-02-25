import 'package:get/get.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

class PremiumPlan {
  const PremiumPlan({
    required this.titleKey,
    required this.descKey,
    required this.fallbackPrice,
  });

  final String titleKey;
  final String descKey;
  final String fallbackPrice;

  String get title => titleKey.tr;
  String get description => descKey.tr;
}

class PremiumController extends GetxController {
  final PurchaseService purchaseService = PurchaseService.to;

  final RxInt selectedPlanIndex = 1.obs;

  final List<PremiumPlan> plans = const [
    PremiumPlan(
      titleKey: 'premium_plan_weekly',
      descKey: 'premium_plan_weekly_desc',
      fallbackPrice: '￦1,900',
    ),
    PremiumPlan(
      titleKey: 'premium_plan_monthly',
      descKey: 'premium_plan_monthly_desc',
      fallbackPrice: '￦5,900',
    ),
    PremiumPlan(
      titleKey: 'premium_plan_yearly',
      descKey: 'premium_plan_yearly_desc',
      fallbackPrice: '￦9,900',
    ),
  ];

  Worker? _premiumWorker;

  @override
  void onInit() {
    super.onInit();
    _premiumWorker = ever(purchaseService.isPremium, (isPremium) {
      if (isPremium) {
        Get.back();
      }
    });
  }

  @override
  void onClose() {
    _premiumWorker?.dispose();
    super.onClose();
  }

  void selectPlan(int index) {
    selectedPlanIndex.value = index;
  }

  void purchase() {
    purchaseService.purchaseProduct(selectedPlanIndex.value);
  }

  void restore() {
    purchaseService.restorePurchases();
  }

  String planPrice(int index) {
    return purchaseService.getProductPrice(index, plans[index].fallbackPrice);
  }
}
