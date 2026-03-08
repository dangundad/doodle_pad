import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

class AppRatingService extends GetxService {
  static AppRatingService get to => Get.find();

  final InAppReview _inAppReview = InAppReview.instance;
  late RateMyApp _rateMyApp;

  @override
  void onInit() {
    super.onInit();
    _initRateMyApp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowRating();
    });
  }

  void _initRateMyApp() {
    _rateMyApp = RateMyApp(
      preferencesPrefix: RateMyAppConfig.PREFIX,
      minDays: RateMyAppConfig.MIN_DAYS,
      minLaunches: RateMyAppConfig.MIN_LAUNCHES,
      remindDays: RateMyAppConfig.REMIND_DAYS,
      remindLaunches: RateMyAppConfig.REMIND_LAUNCHES,
      googlePlayIdentifier: AppUrls.PACKAGE_NAME,
      appStoreIdentifier: RateMyAppConfig.APP_STORE_ID,
    );
  }

  Future<void> checkAndShowRating() async {
    await _rateMyApp.init();
    if (_rateMyApp.shouldOpenDialog) {
      try {
        if (!await _inAppReview.isAvailable()) {
          return;
        }
        await _inAppReview.requestReview();
        await _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
      } catch (e) {
        debugPrint('인앱 리뷰 요청 실패: $e');
      }
    }
  }

  Future<void> openStoreListing() async {
    try {
      if (Platform.isIOS) {
        await _inAppReview.openStoreListing(
          appStoreId: RateMyAppConfig.APP_STORE_ID,
        );
      } else {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('스토어 열기 실패: $e');
    }
  }

  Future<void> resetRatingConditions() async {
    await _rateMyApp.reset();
    _initRateMyApp();
    await _rateMyApp.init();
  }
}

