// ================================================
// DangunDad Flutter App - app_binding.dart Template
// ================================================
// doodle_pad 치환 후 사용
// mbti_pro 프로덕션 패턴 기반

import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/home_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/services/hive_service.dart';

class AppBinding implements Bindings {
  @override
  void dependencies() {
    // HiveService (main.dart에서 이미 등록됨, 체크만 수행)
    if (!Get.isRegistered<HiveService>()) {
      Get.put(HiveService(), permanent: true);
    }

    // 영구 컨트롤러 (앱 전역에서 유지)
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController(), permanent: true);
    }

    // 지연 초기화 컨트롤러 (필요할 때 생성, fenix: true로 재생성 가능)
    Get.lazyPut(() => HomeController(), fenix: true);

    // ---- 앱별 컨트롤러 추가 ----
  }
}
