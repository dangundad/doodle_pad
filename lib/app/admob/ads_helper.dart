// ================================================
// DangunDad Flutter App - ads_helper.dart Template
// ================================================
// 광고 ID 및 GDPR 동의 폼 관리
// {package} 치환 후 사용
// 배포 전 실제 광고 ID로 교체 필요

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static final AdHelper _instance = AdHelper._internal();
  factory AdHelper() => _instance;
  AdHelper._internal();

  // 배너 광고 로드 상태
  static RxBool bannerAdLoaded = false.obs;
  static const banner = 'Banner';
  @visibleForTesting
  static Future<void> Function() loadAndShowConsentFormIfRequired =
      _defaultLoadAndShowConsentFormIfRequired;
  @visibleForTesting
  static Future<InitializationStatus> Function() mobileAdsInitializer = () =>
      MobileAds.instance.initialize();

  static Future<InitializationStatus>? _mobileAdsInitialization;
  static Future<void>? _mobileAdsInitializationGuard;

  static Future<bool> initializeConsentAndAds({
    Future<void> Function()? requestTrackingAuthorizationIfNeeded,
    Future<void> Function()? requestConsentInfoUpdate,
    Future<void> Function()? loadAndShowConsentFormIfRequired,
    Future<bool> Function()? canRequestAds,
    Future<void> Function()? initializeMobileAds,
  }) async {
    try {
      await (requestTrackingAuthorizationIfNeeded ??
          _requestTrackingAuthorizationIfNeeded)();
      await (requestConsentInfoUpdate ??
          _requestConsentInfoUpdateWithDefaults)();
      await (loadAndShowConsentFormIfRequired ??
          AdHelper.loadAndShowConsentFormIfRequired)();

      final resolvedCanRequestAds = await (canRequestAds ?? _canRequestAds)();
      if (!resolvedCanRequestAds) {
        return false;
      }

      await _initializeMobileAdsOnce(initializeMobileAds);
      return true;
    } catch (e) {
      debugPrint('Ad consent and initialization error: $e');
      return false;
    }
  }

  static Future<bool> initializeAdConsent() async {
    try {
      await _requestTrackingAuthorizationIfNeeded();

      final params = ConsentRequestParameters();
      await _requestConsentInfoUpdate(params);

      if (await ConsentInformation.instance.canRequestAds()) {
        return true;
      }

      await loadAndShowConsentFormIfRequired();
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('Ad consent initialization error: $e');
      return false;
    }
  }

  static Future<void> _requestTrackingAuthorizationIfNeeded() async {}

  static Future<void> _requestConsentInfoUpdateWithDefaults() {
    return _requestConsentInfoUpdate(ConsentRequestParameters());
  }

  static Future<bool> _canRequestAds() {
    return ConsentInformation.instance.canRequestAds();
  }

  static Future<void> _requestConsentInfoUpdate(
    ConsentRequestParameters params,
  ) {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );
    return completer.future;
  }

  static Future<void> _defaultLoadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (completer.isCompleted) {
        return;
      }
      if (formError != null) {
        completer.completeError(formError);
        return;
      }
      completer.complete();
    });
    return completer.future;
  }

  static Future<void> _initializeMobileAdsOnce(
    Future<void> Function()? initializeMobileAds,
  ) async {
    if (initializeMobileAds != null) {
      _mobileAdsInitializationGuard ??= () async {
        await initializeMobileAds();
      }();
      await _mobileAdsInitializationGuard;
      return;
    }

    await AdHelper.initializeMobileAds();
  }

  static Future<InitializationStatus?> initializeMobileAds() async {
    try {
      return await (_mobileAdsInitialization ??= mobileAdsInitializer());
    } catch (e) {
      debugPrint('MobileAds initialization error: $e');
      return null;
    }
  }

  static Future<InitializationStatus?> currentInitializationStatus() async {
    final initialization = _mobileAdsInitialization;
    if (initialization == null) {
      return null;
    }

    try {
      return await initialization;
    } catch (e) {
      debugPrint('MobileAds status lookup error: $e');
      return null;
    }
  }

  @visibleForTesting
  static void resetInitializationStateForTest() {
    loadAndShowConsentFormIfRequired = _defaultLoadAndShowConsentFormIfRequired;
    mobileAdsInitializer = () => MobileAds.instance.initialize();
    _mobileAdsInitialization = null;
    _mobileAdsInitializationGuard = null;
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111' // 테스트
          : 'ca-app-pub-9645460570589541/TODO_BANNER'; // TODO: 실제 ID
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716' // 테스트
          : 'ca-app-pub-9645460570589541/TODO_BANNER'; // TODO: 실제 ID
    }
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  /// 전면 광고 ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-9645460570589541/TODO_INTERSTITIAL';
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-9645460570589541/TODO_INTERSTITIAL';
    }
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  /// 보상형 광고 ID
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-9645460570589541/TODO_REWARDED';
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-9645460570589541/TODO_REWARDED';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }
}
