import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';

import 'ads_helper.dart';

class RewardedAdManager extends GetxController {
  static RewardedAdManager get to => Get.find();

  RewardedAd? _rewardedAd;
  final RxBool isAdReady = false.obs;
  final RxBool isAdShowing = false.obs;
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
    // Premium 사용자는 광고 로딩 자체를 하지 않는다 (네트워크/배터리 절약 + 광고 비노출 보장).
    // PurchaseService 캐시가 prime되어 있어 cold start 직후에도 이 guard가 효과적이다.
    if (PurchaseService.isPremiumActive) {
      debugPrint('Rewarded ad skipped: premium active');
      _rewardedAd = null;
      isAdReady.value = false;
      return;
    }
    if (!AdHelper.canRequestAds.value) {
      debugPrint('Rewarded ad skipped: consent/init not ready');
      _rewardedAd = null;
      isAdReady.value = false;
      return;
    }
    final adUnitId = AdHelper.rewardedAdUnitId;
    if (!AdHelper.hasUsableAdUnitId(adUnitId)) {
      debugPrint('Rewarded ad skipped: release ad unit id is not configured');
      _rewardedAd = null;
      isAdReady.value = false;
      return;
    }

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded');
          _rewardedAd = ad;
          isAdReady.value = true;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              isAdShowing.value = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              isAdShowing.value = false;
              ad.dispose();
              _rewardedAd = null;
              isAdReady.value = false;
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              isAdShowing.value = false;
              ad.dispose();
              _rewardedAd = null;
              isAdReady.value = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          isAdReady.value = false;
        },
      ),
    );
  }

  Future<void> showAdIfAvailable({
    Function(RewardItem)? onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) async {
    if (!isAdReady.value || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready, loading...');
      loadAd();
      return;
    }

    if (isAdShowing.value) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isAdShowing.value = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        isAdShowing.value = false;
        ad.dispose();
        _rewardedAd = null;
        isAdReady.value = false;
        onAdClosed?.call();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        isAdShowing.value = false;
        ad.dispose();
        _rewardedAd = null;
        isAdReady.value = false;
        onAdClosed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward?.call(reward);
      },
    );
  }

  @override
  void onClose() {
    _consentWorker?.dispose();
    _consentWorker = null;
    _rewardedAd?.dispose();
    super.onClose();
  }
}
