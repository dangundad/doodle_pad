// ================================================
// DangunDad Flutter App - ads_helper.dart Template
// ================================================
// 광고 ID 및 GDPR 동의 폼 관리
// {package} 치환 후 사용
// 배포 전 실제 광고 ID로 교체 필요

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

  // 배너 타입 상수
  static const banner = 'Banner';

  /// AdMob 동의 폼 초기화 (GDPR/CCPA 준수)
  static Future<void> initializeAdConsent() async {
    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          final formStatus =
              await ConsentInformation.instance.getConsentStatus();
          debugPrint('Ad consent status: $formStatus');

          if (formStatus != ConsentStatus.required) return;
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            _showConsentForm();
          }
        },
        (error) {
          debugPrint('Consent info request error: $error');
        },
      );
    } catch (e) {
      debugPrint('Ad consent initialization error: $e');
    }
  }

  static void _showConsentForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        consentForm.show((formError) async {
          if (formError != null) {
            debugPrint(
              'Consent form error: ${formError.errorCode} - ${formError.message}',
            );
          }
        });
      },
      (formError) {
        debugPrint(
          'Consent form load error: ${formError.errorCode} - ${formError.message}',
        );
      },
    );
  }

  // ---- 테스트 광고 ID (배포 전 실제 ID로 교체) ----
  // Android 테스트: ca-app-pub-3940256099942544/...
  // iOS 테스트: ca-app-pub-3940256099942544/...

  /// 배너 광고 ID
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
