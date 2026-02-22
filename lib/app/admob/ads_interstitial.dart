// ================================================
// DangunDad Flutter App - ads_interstitial.dart Template
// ================================================
// 전면 광고 매니저 (GetxController 기반, mbti_pro 패턴)

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

import 'ads_helper.dart';

class InterstitialAdManager extends GetxController {
  static InterstitialAdManager get to => Get.find();

  InterstitialAd? _interstitialAd;
  final RxBool isAdReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAd();
  }

  Future<void> loadAd() async {
    await InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          isAdReady.value = true;

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  isAdReady.value = false;
                  loadAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('Interstitial ad failed to show: $error');
                  ad.dispose();
                  _interstitialAd = null;
                  isAdReady.value = false;
                  loadAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
          isAdReady.value = false;
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (_interstitialAd != null && isAdReady.value) {
      _interstitialAd!.show();
    } else {
      loadAd();
    }
  }

  @override
  void onClose() {
    _interstitialAd?.dispose();
    super.onClose();
  }
}
