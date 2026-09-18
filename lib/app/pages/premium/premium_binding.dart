import 'package:get/get.dart';
import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PurchaseService>()) {
      Get.put<PurchaseService>(PurchaseService(), permanent: true);
    }

    // PremiumPage 가 쓰는 컨트롤러는 이 라우트가 소유한다.
    //
    // 예전에는 `AppBinding` 의 `Get.lazyPut`(fenix 아님) 하나에만 기대고
    // 있었는데, 첫 진입에서 팩토리가 소비돼 인스턴스가 되고 라우트를 닫을 때
    // (SmartManagement.full) 그 인스턴스가 정리되면 **다시 만들 방법이 없어져**
    // 두 번째 진입에서 `"PremiumController" not found` 로 화면이 깨졌다.
    // fenix: true 는 정리 후에도 팩토리를 남겨 다음 find 때 새로 만들어 준다.
    Get.lazyPut<PremiumController>(() => PremiumController(), fenix: true);
  }
}
