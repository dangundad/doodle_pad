import 'package:hive_ce/hive.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/services/activity_log_service.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/controllers/history_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/controllers/stats_controller.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/services/app_rating_service.dart';
import 'package:doodle_pad/app/controllers/premium_controller.dart';

class AppBinding implements Bindings {
  static Future<void> initializeServices() async {
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
      } catch (e) {
        Get.log('[AppBinding] Hive reopen failed: $e');
      }
    }

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
    if (!Get.isRegistered<DoodleController>()) {
      Get.put(DoodleController(), permanent: true);
    }

    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController(), permanent: true);
    }

    if (!Get.isRegistered<ActivityLogService>()) {
      Get.put(ActivityLogService(), permanent: true);
    }

    if (!Get.isRegistered<HistoryController>()) {
      Get.lazyPut(() => HistoryController());
    }

    if (!Get.isRegistered<StatsController>()) {
      Get.lazyPut(() => StatsController());
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
