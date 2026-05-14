import 'package:hive_ce/hive.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/services/app_rating_service.dart';
import 'package:doodle_pad/app/controllers/premium_controller.dart';

class AppBinding implements Bindings {
  static const List<String> _legacyBoxNames = ['phase1_activity_log'];
  static const String _legacyPurgeFlagKey = 'legacy_boxes_purged_v1';
  static const String _settingsBoxName = 'doodle_settings_v1';

  static Future<void> initializeCoreServices() async {
    if (!Get.isRegistered<HiveService>()) {
      await HiveService.init();
      Get.put(HiveService(), permanent: true);
    } else {
      try {
        if (!Hive.isBoxOpen('settings')) {
          await Hive.openBox('settings');
        }
        if (!Hive.isBoxOpen('app_data')) {
          await Hive.openBox('app_data');
        }
        if (!Hive.isBoxOpen('drawings')) {
          await Hive.openBox<Drawing>('drawings');
        }
      } catch (e) {
        Get.log('[AppBinding] Hive reopen failed: $e');
      }
    }

    await SettingController.ensureBoxOpen();
    await _purgeLegacyHiveBoxes();
  }

  static Future<void> _purgeLegacyHiveBoxes() async {
    final settingsBox = Hive.box(_settingsBoxName);
    if (settingsBox.get(_legacyPurgeFlagKey) == true) return;

    for (final name in _legacyBoxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
        await Hive.deleteBoxFromDisk(name);
      } catch (e) {
        Get.log('[AppBinding] legacy box purge failed ($name): $e');
      }
    }
    await settingsBox.put(_legacyPurgeFlagKey, true);
  }

  static Future<void> initializeServices() async {
    await initializeCoreServices();
    _ensureDependencyServices();
  }

  @override
  void dependencies() {
    if (!Get.isRegistered<PurchaseService>()) {
      Get.put(PurchaseService(), permanent: true);
    }

    if (!Get.isRegistered<PremiumController>()) {
      Get.lazyPut(() => PremiumController());
    }

    _ensureDependencyServices();
  }

  static void _ensureDependencyServices() {
    // SettingController는 반드시 DoodleController보다 먼저 등록한다.
    // DoodleController.onInit -> _bindShakeToClearSetting()이 SettingController.to에
    // `ever` 리스너를 거는데, SettingController가 아직 없으면 조용히 패스해
    // shakeToClearEnabled 토글이 가속도계 구독에 반영되지 않는 회귀가 생긴다.
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController(), permanent: true);
    }

    if (!Get.isRegistered<DoodleController>()) {
      Get.put(DoodleController(), permanent: true);
    }

    if (!Get.isRegistered<InterstitialAdManager>()) {
      Get.put(InterstitialAdManager(), permanent: true);
    }

    if (!Get.isRegistered<RewardedAdManager>()) {
      Get.put(RewardedAdManager(), permanent: true);
    }

    if (!Get.isRegistered<AppRatingService>()) {
      Get.put(AppRatingService(), permanent: true);
    }
  }
}
