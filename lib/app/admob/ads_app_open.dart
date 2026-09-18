// 앱 오프닝(App Open) 광고 매니저. 앱이 백그라운드에서 일정 시간 이상 머문 뒤
// 포그라운드로 복귀할 때만 노출한다. 콜드 스타트에서는 띄우지 않는다
// (스플래시 없이 바로 캔버스로 들어가는 앱이라 첫 인상을 광고로 시작하지 않는다).
//
// 4시간 캐시 + 복귀 횟수 임계 + 최소 간격으로 제어하고, 프리미엄 화면이나
// 다이얼로그/바텀시트가 떠 있는 동안에는 건너뛴다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import 'ads_helper.dart';

class AppOpenAdManager extends GetxService with WidgetsBindingObserver {
  static AppOpenAdManager get to => Get.find();

  static const String _lastAdTimeKey = 'last_app_open_ad_time';
  static const String _foregroundCountKey = 'app_open_foreground_count';

  /// 이 시간보다 짧게 백그라운드에 머문 복귀는 "앱을 다시 연 것"으로 보지 않는다.
  /// (사진 선택기·공유 시트에서 돌아오는 경우가 여기 해당한다)
  static const Duration minBackgroundDuration = Duration(minutes: 1);

  /// 로드한 광고를 재사용할 수 있는 최대 시간. AdMob 권장값.
  static const Duration maxCacheDuration = Duration(hours: 4);

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime? _lastPausedAt;
  DateTime? _appOpenLoadTime;
  Worker? _premiumWorker;

  /// 테스트 주입용 시계.
  @visibleForTesting
  DateTime Function() nowFn = DateTime.now;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeLastAdTime());
    unawaited(loadAd());

    if (Get.isRegistered<PurchaseService>()) {
      _premiumWorker = ever<bool>(PurchaseService.to.isPremium, (isPremium) {
        if (isPremium) {
          _appOpenAd?.dispose();
          _appOpenAd = null;
          _appOpenLoadTime = null;
          debugPrint('Premium purchased - app open ad disposed');
          return;
        }
        if (_appOpenAd == null) unawaited(loadAd());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedAt = nowFn();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    if (_isShowingAd || PurchaseService.isPremiumActive) return;

    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;
    if (pausedAt == null) {
      if (!isAdAvailable) unawaited(loadAd());
      return;
    }

    if (nowFn().difference(pausedAt) >= minBackgroundDuration) {
      unawaited(showAdIfAvailable());
    } else if (!isAdAvailable) {
      unawaited(loadAd());
    }
  }

  /// 설치 직후 첫 복귀에 광고가 터지지 않도록 기준 시각을 미리 심어 둔다.
  Future<void> _initializeLastAdTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt(_lastAdTimeKey) == null) {
        await prefs.setInt(_lastAdTimeKey, nowFn().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('App open ad: failed to seed last ad time: $e');
    }
  }

  bool get isAdAvailable => _appOpenAd != null && _appOpenLoadTime != null;

  Future<void> loadAd() async {
    if (_isLoadingAd || _appOpenAd != null) return;
    if (PurchaseService.isPremiumActive) {
      debugPrint('App open ad skipped: premium active');
      return;
    }

    final adUnitId = AdHelper.appOpenAdUnitId;
    if (!AdHelper.isPlatformAdMobConfigured ||
        !AdHelper.hasUsableAdUnitId(adUnitId)) {
      debugPrint('App open ad skipped: ad unit id is not configured');
      return;
    }

    _isLoadingAd = true;

    // 광고 초기화는 첫 프레임 이후로 지연되므로 초기화 시도가 끝날 때까지 기다린다.
    await AdHelper.mobileAdsReady;

    // 동의를 얻지 못해 SDK 초기화를 건너뛴 경우 광고를 요청하지 않는다.
    if (!AdHelper.canRequestAds || PurchaseService.isPremiumActive) {
      _isLoadingAd = false;
      return;
    }

    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAd = false;
          // 로드가 진행되는 동안 프리미엄 구매가 완료됐을 수 있다. show 단계에서도
          // 막히지만, 여기서 폐기해야 광고 객체가 남지 않는다.
          if (PurchaseService.isPremiumActive) {
            ad.dispose();
            _appOpenAd = null;
            _appOpenLoadTime = null;
            return;
          }
          debugPrint('App open ad loaded');
          _appOpenAd = ad;
          _appOpenLoadTime = nowFn();
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> showAdIfAvailable() async {
    if (PurchaseService.isPremiumActive) return;
    if (_shouldSkipForCurrentUi()) {
      if (!isAdAvailable) unawaited(loadAd());
      return;
    }

    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('App open ad: prefs unavailable: $e');
      return;
    }

    final foregroundCount = (prefs.getInt(_foregroundCountKey) ?? 0) + 1;
    await prefs.setInt(_foregroundCountKey, foregroundCount);
    if (foregroundCount < AdHelper.AD_SHOW_THRESHOLD) {
      if (!isAdAvailable) unawaited(loadAd());
      return;
    }

    final lastAdTime = prefs.getInt(_lastAdTimeKey);
    if (lastAdTime != null) {
      final minutesSinceLastAd =
          (nowFn().millisecondsSinceEpoch - lastAdTime) / (1000 * 60);
      if (minutesSinceLastAd < AdHelper.APP_OPEN_INTERVAL_MINUTES) return;
    }

    if (!isAdAvailable || _isShowingAd) {
      if (!isAdAvailable) unawaited(loadAd());
      return;
    }

    // 캐시가 만료된 광고는 버리고 새로 받는다.
    final loadTime = _appOpenLoadTime;
    if (loadTime == null ||
        nowFn().subtract(maxCacheDuration).isAfter(loadTime)) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadTime = null;
      unawaited(loadAd());
      return;
    }

    _isShowingAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App open ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        unawaited(loadAd());
      },
      onAdDismissedFullScreenContent: (ad) async {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        await prefs.setInt(_lastAdTimeKey, nowFn().millisecondsSinceEpoch);
        await prefs.setInt(_foregroundCountKey, 0);
        unawaited(loadAd());
      },
    );
    _appOpenAd!.show();
  }

  /// 광고를 띄우면 안 되는 화면/상태인지 판단한다.
  /// 그리기 화면(DRAW)은 허용한다 — 1분 이상 백그라운드에 머문 뒤의 복귀이므로
  /// 획을 긋는 도중에 끼어드는 상황이 아니다.
  @visibleForTesting
  bool shouldSkipForCurrentUi() => _shouldSkipForCurrentUi();

  bool _shouldSkipForCurrentUi() {
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return true;
    const blocked = {Routes.PREMIUM};
    return blocked.contains(Get.currentRoute);
  }

  @override
  void onClose() {
    _premiumWorker?.dispose();
    _premiumWorker = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
