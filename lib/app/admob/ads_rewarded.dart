// ================================================
// DangunDad Flutter App - ads_rewarded.dart Template
// ================================================
// 보상형 광고 매니저 (GetxController 기반, mbti_pro 패턴)

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

import 'ads_helper.dart';

class RewardedAdManager extends GetxController {
  static RewardedAdManager get to => Get.find();

  RewardedAd? _rewardedAd;
  final RxBool isAdReady = false.obs;
  final RxBool isAdShowing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAd();
  }

  Future<void> loadAd() async {
    await RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
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
              _rewardedAd = null;
              isAdReady.value = false;
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              isAdShowing.value = false;
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
        _rewardedAd = null;
        isAdReady.value = false;
        onAdClosed?.call();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        isAdShowing.value = false;
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
    _rewardedAd?.dispose();
    super.onClose();
  }
}
