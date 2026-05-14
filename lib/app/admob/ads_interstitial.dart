import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';

import 'ads_helper.dart';

class InterstitialAdManager extends GetxController {
  static InterstitialAdManager get to => Get.find();

  InterstitialAd? _interstitialAd;
  final RxBool isAdReady = false.obs;
  Worker? _consentWorker;

  @override
  void onInit() {
    super.onInit();
    if (AdHelper.canRequestAds.value) {
      loadAd();
    } else {
      _consentWorker = ever<bool>(AdHelper.canRequestAds, (canRequest) {
        if (canRequest) {
          _consentWorker?.dispose();
          _consentWorker = null;
          loadAd();
        }
      });
    }
  }

  Future<void> loadAd() async {
    // Premium 사용자는 광고 로딩 자체를 하지 않는다.
    // PurchaseService 캐시 prime + _syncAdsForPremiumStatus와 함께 다중 방어선을 형성한다.
    if (PurchaseService.isPremiumActive) {
      debugPrint('Interstitial ad skipped: premium active');
      _interstitialAd = null;
      isAdReady.value = false;
      return;
    }
    if (!AdHelper.canRequestAds.value) {
      debugPrint('Interstitial ad skipped: consent/init not ready');
      _interstitialAd = null;
      isAdReady.value = false;
      return;
    }
    final adUnitId = AdHelper.interstitialAdUnitId;
    if (!AdHelper.hasUsableAdUnitId(adUnitId)) {
      debugPrint(
        'Interstitial ad skipped: release ad unit id is not configured',
      );
      _interstitialAd = null;
      isAdReady.value = false;
      return;
    }

    await InterstitialAd.load(
      adUnitId: adUnitId,
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
    if (PurchaseService.isPremiumActive) return;
    if (_interstitialAd != null && isAdReady.value) {
      _interstitialAd!.show();
    } else {
      loadAd();
    }
  }

  @override
  void onClose() {
    _consentWorker?.dispose();
    _consentWorker = null;
    _interstitialAd?.dispose();
    super.onClose();
  }
}
