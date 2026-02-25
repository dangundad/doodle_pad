import 'package:get/get.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PurchaseService>()) {
      Get.put<PurchaseService>(PurchaseService(), permanent: true);
    }
  }
}
