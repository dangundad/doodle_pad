import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/services/hive_service.dart';

class AppBinding implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HiveService>()) {
      Get.put(HiveService(), permanent: true);
    }

    if (!Get.isRegistered<DoodleController>()) {
      Get.put(DoodleController(), permanent: true);
    }
  }
}
