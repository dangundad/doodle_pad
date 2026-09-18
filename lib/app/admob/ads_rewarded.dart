import 'dart:async';

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
  bool _isLoading = false;
  Worker? _premiumWorker;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadAd());

    if (Get.isRegistered<PurchaseService>()) {
      _premiumWorker = ever<bool>(PurchaseService.to.isPremium, (isPremium) {
        if (isPremium) {
          _rewardedAd?.dispose();
          _rewardedAd = null;
          isAdReady.value = false;
          debugPrint('Premium purchased - rewarded ad disposed');
          return;
        }
        if (_rewardedAd == null) unawaited(loadAd());
      });
    }
  }

  Future<void> loadAd() async {
    // 중복 로드 방지: 이미 요청이 진행 중이거나 준비된 광고가 있으면 스킵
    if (_isLoading || _rewardedAd != null) return;

    // Premium 사용자는 광고 로딩 자체를 하지 않는다 (네트워크/배터리 절약 + 광고 비노출 보장).
    // PurchaseService 캐시가 prime되어 있어 cold start 직후에도 이 guard가 효과적이다.
    if (PurchaseService.isPremiumActive) {
      debugPrint('Rewarded ad skipped: premium active');
      _rewardedAd = null;
      isAdReady.value = false;
      return;
    }
    final adUnitId = AdHelper.rewardedAdUnitId;
    if (!AdHelper.isPlatformAdMobConfigured ||
        !AdHelper.hasUsableAdUnitId(adUnitId)) {
      debugPrint('Rewarded ad skipped: ad unit id is not configured');
      _rewardedAd = null;
      isAdReady.value = false;
      return;
    }

    _isLoading = true;

    // 광고 초기화는 첫 프레임 이후로 지연되므로 초기화 시도가 끝날 때까지 기다린다.
    await AdHelper.mobileAdsReady;

    // 동의를 얻지 못해 SDK 초기화를 건너뛴 경우 광고를 요청하지 않는다.
    if (!AdHelper.canRequestAds || PurchaseService.isPremiumActive) {
      debugPrint('Rewarded ad skipped: consent/init not ready');
      _isLoading = false;
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
          _isLoading = false;
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
          _isLoading = false;
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
    _premiumWorker?.dispose();
    _premiumWorker = null;
    _rewardedAd?.dispose();
    super.onClose();
  }
}
