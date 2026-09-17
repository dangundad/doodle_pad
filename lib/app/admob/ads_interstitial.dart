import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';

import 'ads_helper.dart';

class InterstitialAdManager extends GetxController {
  static InterstitialAdManager get to => Get.find();

  // ───────────────────────── 노출 빈도 제한 ─────────────────────────
  //
  // 전면 광고는 "한 작업을 끝낸" 순간(작품 저장 / 갤러리 저장 완료)에만 띄운다.
  // 그리는 도중에는 절대 끼어들지 않는다. 그림 앱에서 작업 흐름을 끊는 광고는
  // 이탈로 직결되므로, 노출 지점보다 빈도 제한을 더 보수적으로 잡는다.

  /// 직전 노출로부터 이 시간이 지나야 다시 띄운다.
  static const Duration minShowInterval = Duration(minutes: 3);

  /// 앱 실행(프로세스) 당 최대 노출 횟수.
  static const int maxShowsPerSession = 2;

  /// 이 횟수만큼의 저장은 광고 없이 지나간다.
  /// 앱을 처음 써 보는 사용자의 첫 저장을 광고로 맞이하지 않기 위함.
  static const int milestonesBeforeFirstAd = 1;

  /// 저장 완료 토스트를 사용자가 볼 수 있도록 두는 지연.
  static const Duration showDelay = Duration(milliseconds: 1200);

  int _milestoneCount = 0;
  int _shownCount = 0;
  DateTime? _lastShownAt;

  /// 테스트 주입용 시계.
  @visibleForTesting
  DateTime Function() nowFn = DateTime.now;

  /// 테스트에서 지연 없이 즉시 노출을 검증하기 위한 seam.
  @visibleForTesting
  bool skipShowDelayForTest = false;

  @visibleForTesting
  int get shownCountForTest => _shownCount;

  @visibleForTesting
  int get milestoneCountForTest => _milestoneCount;

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

  /// 지금 전면 광고를 띄워도 되는 상태인지.
  bool get canShowNow {
    if (PurchaseService.isPremiumActive) return false;
    if (_milestoneCount <= milestonesBeforeFirstAd) return false;
    if (_shownCount >= maxShowsPerSession) return false;
    final last = _lastShownAt;
    if (last != null && nowFn().difference(last) < minShowInterval) {
      return false;
    }
    return true;
  }

  /// 사용자가 한 작업을 끝냈음을 알린다(작품 저장 / 갤러리 저장 완료).
  ///
  /// 빈도 제한을 통과하고 광고가 준비되어 있을 때만 노출한다. 준비되지 않았으면
  /// 조용히 다음 로드만 트리거하고 사용자 흐름은 막지 않는다.
  /// 그리는 도중에는 절대 호출하지 말 것.
  Future<void> notifyMilestoneReached() async {
    _milestoneCount++;
    if (!canShowNow) return;
    if (_interstitialAd == null || !isAdReady.value) {
      // 다음 기회를 위해 미리 받아둔다. 이번 저장은 광고 없이 지나간다.
      unawaited(loadAd());
      return;
    }

    if (!skipShowDelayForTest) {
      // 저장 완료 토스트를 사용자가 읽을 시간을 준다.
      await Future<void>.delayed(showDelay);
      // 대기 중 프리미엄 전환/광고 소진이 있었을 수 있으므로 다시 확인한다.
      if (!canShowNow) return;
      if (_interstitialAd == null || !isAdReady.value) return;
    }

    _shownCount++;
    _lastShownAt = nowFn();
    _interstitialAd!.show();
  }

  /// 실제 노출이 일어났을 때의 상태 전이만 흉내낸다(광고 SDK 호출 없음).
  @visibleForTesting
  void markShownForTest() {
    _shownCount++;
    _lastShownAt = nowFn();
  }

  @visibleForTesting
  void resetFrequencyStateForTest() {
    _milestoneCount = 0;
    _shownCount = 0;
    _lastShownAt = null;
    nowFn = DateTime.now;
    skipShowDelayForTest = false;
  }

  @override
  void onClose() {
    _consentWorker?.dispose();
    _consentWorker = null;
    _interstitialAd?.dispose();
    super.onClose();
  }
}
