import 'package:get/get.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

class PremiumPlan {
  const PremiumPlan({
    required this.productId,
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.fallbackPrice,
    this.badgeKey,
  });

  final String productId;
  final String emoji;
  final String titleKey;
  final String descKey;
  final String fallbackPrice;
  final String? badgeKey;

  String get title => titleKey.tr;
  String get description => descKey.tr;
  String? get badge => badgeKey?.tr;
}

class PremiumController extends GetxController {
  final PurchaseService purchaseService = PurchaseService.to;

  final RxInt selectedPlanIndex = 1.obs;

  final List<PremiumPlan> plans = const [
    PremiumPlan(
      productId: PurchaseConstants.PREMIUM_SMALL_ANDROID,
      emoji: '☕',
      titleKey: 'premium_support_small_title',
      descKey: 'premium_support_small_desc',
      fallbackPrice: '￦2,900',
    ),
    PremiumPlan(
      productId: PurchaseConstants.PREMIUM_MEDIUM_ANDROID,
      emoji: '🍔',
      titleKey: 'premium_support_medium_title',
      descKey: 'premium_support_medium_desc',
      fallbackPrice: '￦5,900',
      badgeKey: 'premium_support_medium_badge',
    ),
    PremiumPlan(
      productId: PurchaseConstants.PREMIUM_LARGE_ANDROID,
      emoji: '🍽️',
      titleKey: 'premium_support_large_title',
      descKey: 'premium_support_large_desc',
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
