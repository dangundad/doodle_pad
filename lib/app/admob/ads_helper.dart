import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:gma_mediation_applovin/gma_mediation_applovin.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/*
광고 형식	샘플 광고 단위 ID
앱 오프닝 광고	ca-app-pub-3940256099942544/9257395921
적응형 배너	ca-app-pub-3940256099942544/9214589741
고정 크기 배너	ca-app-pub-3940256099942544/6300978111
전면 광고	ca-app-pub-3940256099942544/1033173712
동영상 전면 광고	ca-app-pub-3940256099942544/8691691433
보상형 광고	ca-app-pub-3940256099942544/5224354917
보상형 전면 광고	ca-app-pub-3940256099942544/5354046379
네이티브 광고 고급형	ca-app-pub-3940256099942544/2247696110
네이티브 동영상 광고 고급형	ca-app-pub-3940256099942544/1044960115
*/

/*--------iOS 테스트 ID --------
앱 오픈	ca-app-pub-3940256099942544/5575463023
적응형 배너	ca-app-pub-3940256099942544/2435281174
고정 크기 배너	ca-app-pub-3940256099942544/2934735716  //= 이게 Flutter에서 기본 배너
전면 광고	ca-app-pub-3940256099942544/4411468910
삽입 동영상	ca-app-pub-3940256099942544/5135589807
보상됨	ca-app-pub-3940256099942544/1712485313
보상형 전면 광고	ca-app-pub-3940256099942544/6978759866
네이티브 고급	ca-app-pub-3940256099942544/3986624511
네이티브 고급 비디오	ca-app-pub-3940256099942544/2521693316
*/

/*-----------------Anroid 실제 광고 단위 ID-----------------
//appid android : ca-app-pub-9645460570589541~8667399406
//배너 : ca-app-pub-9645460570589541/6109518827
//전면 : ca-app-pub-9645460570589541/9565935140
//앱 오프닝 : ca-app-pub-9645460570589541/9390288288
//네이티브 고급 광고 : ca-app-pub-9645460570589541/8825989538
//보상형 : ca-app-pub-9645460570589541/8252853478
*/

/*-----------------iOS 실제 광고 단위 ID-----------------
iOS 광고 단위는 아직 AdMob 콘솔에서 발급받지 않았다.
발급 후에는 아래 --dart-define 키로 주입한다(빌드 스크립트에서 관리).
  DOODLE_PAD_ADMOB_BANNER_IOS
  DOODLE_PAD_ADMOB_INTERSTITIAL_IOS
  DOODLE_PAD_ADMOB_NATIVE_IOS
  DOODLE_PAD_ADMOB_APP_OPEN_IOS
  DOODLE_PAD_ADMOB_REWARDED_IOS
앱 ID(GADApplicationIdentifier)는 ios/Flutter/Release.xcconfig 의
IOS_ADMOB_APP_ID 로 주입한다.
*/

class AdHelper {
  static final AdHelper _instance = AdHelper._internal();
  factory AdHelper() => _instance;
  AdHelper._internal();

  // ───────────────────────── 광고 빈도 제어 상수 ─────────────────────────

  /// 앱 오프닝: 포그라운드 복귀 N회째부터 노출 후보로 삼는다.
  // ignore: constant_identifier_names
  static const int AD_SHOW_THRESHOLD = 2;

  /// 앱 오프닝: 직전 노출로부터 이 시간(분)이 지나야 다시 띄운다.
  // ignore: constant_identifier_names
  static const int APP_OPEN_INTERVAL_MINUTES = 30;

  // 미디에이션 초기화 플래그
  static bool _isMediationInitialized = false;

  // 동의 상태 캐시 (미디에이션 설정용)
  static bool? _gdprConsent;
  static bool? _ccpaConsent;

  // UMP 동의 결과 / Mobile Ads SDK 초기화 상태
  static bool _hasConsentToRequestAds = false;
  static bool _isMobileAdsInitialized = false;
  static Completer<void> _mobileAdsReady = Completer<void>();

  // 설정 화면에서 개인정보 옵션(UMP) 폼을 다시 열 수 있는지 여부
  static final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(
    false,
  );

  // iOS AdMob 광고 단위는 AdMob 콘솔에서 별도 발급 후 --dart-define 으로 주입한다.
  // 주입되지 않은 릴리스 빌드에서는 iOS 광고를 통째로 건너뛴다(테스트 ID 유출 방지).
  static const String _iosBannerAdUnitId = String.fromEnvironment(
    'DOODLE_PAD_ADMOB_BANNER_IOS',
  );
  static const String _iosInterstitialAdUnitId = String.fromEnvironment(
    'DOODLE_PAD_ADMOB_INTERSTITIAL_IOS',
  );
  static const String _iosNativeAdUnitId = String.fromEnvironment(
    'DOODLE_PAD_ADMOB_NATIVE_IOS',
  );
  static const String _iosAppOpenAdUnitId = String.fromEnvironment(
    'DOODLE_PAD_ADMOB_APP_OPEN_IOS',
  );
  static const String _iosRewardedAdUnitId = String.fromEnvironment(
    'DOODLE_PAD_ADMOB_REWARDED_IOS',
  );

  static bool get _iosAdMobConfigured =>
      _iosBannerAdUnitId.isNotEmpty && _iosInterstitialAdUnitId.isNotEmpty;

  /// 테스트에서 플랫폼 게이트를 강제로 열고 닫기 위한 seam.
  /// `flutter test` 호스트는 Android/iOS 가 아니라 광고가 전부 꺼지므로,
  /// 긍정 경로를 검증하려면 이 값을 지정해야 한다.
  @visibleForTesting
  static bool? platformAdMobConfiguredOverride;

  /// 테스트에서 "SDK 초기화 완료" 상태를 흉내내기 위한 seam.
  @visibleForTesting
  static bool? mobileAdsInitializedOverride;

  static bool get isPlatformAdMobConfigured {
    final override = platformAdMobConfiguredOverride;
    if (override != null) return override;
    if (Platform.isAndroid) return true;
    // 디버그(시뮬레이터/실기기)에서는 테스트 광고를 위해 항상 활성화.
    // 릴리스는 실 iOS 광고 ID를 --dart-define 으로 주입했을 때만 켠다.
    if (Platform.isIOS) return kDebugMode || _iosAdMobConfigured;
    return false;
  }

  /// 실제로 광고를 요청해도 되는 상태인지 여부.
  /// 플랫폼 광고 ID 설정 + UMP 동의 + SDK 초기화가 모두 끝나야 true가 된다.
  static bool get canRequestAds =>
      isPlatformAdMobConfigured &&
      (mobileAdsInitializedOverride ?? _isMobileAdsInitialized);

  /// 광고 SDK 초기화 "시도"가 끝났음을 알리는 게이트.
  ///
  /// 광고 초기화는 첫 프레임 이후로 지연되므로 광고 위젯은 이 future를 기다린 뒤
  /// [canRequestAds]로 요청 가능 여부를 판단한다. 동의를 얻지 못해 초기화를
  /// 건너뛴 경우에도 반드시 완료된다 — 완료되지 않으면 이 future를 기다리는
  /// async 컨티뉴에이션이 dispose된 State를 붙잡아 회수되지 않는다.
  static Future<void> get mobileAdsReady => _mobileAdsReady.future;

  static void _settleMobileAdsGate() {
    if (!_mobileAdsReady.isCompleted) _mobileAdsReady.complete();
  }

  // 배너 로드 상태
  static RxBool bannerAdLoaded = false.obs;

  // 네이티브 광고 로드 상태
  static RxBool nativeAdLoaded = false.obs;

  // 배너 Const Type
  // 배너는 홈 하단에 같은 형태로만 노출되므로 하나로 통합한다.
  static const banner = 'Banner';

  /// 광고 단위 ID가 비어 있지 않은지(요청해도 되는지) 확인한다.
  static bool hasUsableAdUnitId(String adUnitId) => adUnitId.trim().isNotEmpty;

  //* 배너 광고
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        //test
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        return 'ca-app-pub-9645460570589541/6109518827';
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        // iOS 테스트: 고정 크기 배너 (실 ID 미설정이어도 테스트 광고 노출)
        return 'ca-app-pub-3940256099942544/2934735716';
      } else {
        return _iosBannerAdUnitId;
      }
    } else {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        return 'ca-app-pub-9645460570589541/6109518827';
      }
    }
  }

  //* 전면 광고
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        //test
        return 'ca-app-pub-3940256099942544/1033173712';
      } else {
        return 'ca-app-pub-9645460570589541/9565935140';
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        // iOS 테스트: 전면 광고
        return 'ca-app-pub-3940256099942544/4411468910';
      } else {
        return _iosInterstitialAdUnitId;
      }
    } else {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else {
        return 'ca-app-pub-9645460570589541/9565935140';
      }
    }
  }

  //* 네이티브 고급광고
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        //test
        return 'ca-app-pub-3940256099942544/2247696110';
      } else {
        return 'ca-app-pub-9645460570589541/8825989538';
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        // iOS 테스트: 네이티브 고급
        return 'ca-app-pub-3940256099942544/3986624511';
      } else {
        return _iosNativeAdUnitId;
      }
    } else {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/2247696110';
      } else {
        return 'ca-app-pub-9645460570589541/8825989538';
      }
    }
  }

  //* 앱 오프닝 광고
  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        //test
        return 'ca-app-pub-3940256099942544/9257395921';
      } else {
        return 'ca-app-pub-9645460570589541/9390288288';
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        // iOS 테스트: 앱 오프닝
        return 'ca-app-pub-3940256099942544/5575463023';
      } else {
        return _iosAppOpenAdUnitId;
      }
    } else {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/9257395921';
      } else {
        return 'ca-app-pub-9645460570589541/9390288288';
      }
    }
  }

  //* 보상형 광고
  // 노출 지점(프리미엄 브러시 해금)은 DoodleController 가 담당한다.
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        //test
        return 'ca-app-pub-3940256099942544/5224354917';
      } else {
        return 'ca-app-pub-9645460570589541/8252853478';
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        // iOS 테스트: 보상형
        return 'ca-app-pub-3940256099942544/1712485313';
      } else {
        return _iosRewardedAdUnitId;
      }
    } else {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/5224354917';
      } else {
        return 'ca-app-pub-9645460570589541/8252853478';
      }
    }
  }

  /// 앱 시작(첫 프레임 이후) 시 한 번만 호출되는 광고 초기화.
  ///
  /// UMP 동의 → (iOS) ATT → Mobile Ads SDK 초기화 순서를 보장한다.
  /// 동의를 얻지 못하면 SDK를 초기화하지 않아 광고 요청 자체가 차단된다.
  static Future<void> initializeAds() async {
    if (!isPlatformAdMobConfigured) {
      debugPrint('AdMob 초기화 건너뜀: 이 플랫폼의 광고 ID가 설정되지 않았습니다.');
      privacyOptionsRequired.value = false;
      _settleMobileAdsGate();
      return;
    }

    try {
      final hasConsent = await initializeAdConsent();
      if (!hasConsent) {
        debugPrint('⛔ 사용자 동의가 없어 광고 초기화를 중단합니다.');
        _settleMobileAdsGate();
        return;
      }

      await requestAttIfNeeded();
      await initializeMobileAds();
    } catch (e) {
      debugPrint('Ad consent and initialization error: $e');
      _settleMobileAdsGate();
    }
  }

  /// 미디에이션 초기화를 동의 결과에 따라 수행
  /// [hasGdprConsent] GDPR 동의 여부 (null이면 미디에이션에 설정하지 않음)
  /// [hasCcpaConsent] CCPA 동의 여부 (null이면 미디에이션에 설정하지 않음)
  static Future<void> initializeMediationWithConsent({
    bool? hasGdprConsent,
    bool? hasCcpaConsent,
  }) async {
    if (_isMediationInitialized) {
      debugPrint('⚠️ 미디에이션이 이미 초기화되었습니다.');
      return;
    }

    try {
      debugPrint('🔧 미디에이션 초기화 시작 (동의 기반)...');

      // AppLovin 미디에이션 개인정보 설정
      try {
        final applovin = GmaMediationApplovin();
        if (hasGdprConsent != null) {
          await applovin.setHasUserConsent(hasGdprConsent);
          debugPrint('AppLovin GDPR 동의: $hasGdprConsent');
        }
        if (hasCcpaConsent != null) {
          // CCPA: DoNotSell은 동의하지 않으면 true (판매 금지)
          await applovin.setDoNotSell(!hasCcpaConsent);
          debugPrint('AppLovin DoNotSell: ${!hasCcpaConsent}');
        }
        debugPrint('✅ AppLovin 미디에이션 설정 완료');
      } catch (e) {
        debugPrint('❌ AppLovin 미디에이션 설정 오류: $e');
      }

      // Unity 미디에이션 개인정보 설정
      try {
        final unity = GmaMediationUnity();
        if (hasGdprConsent != null) {
          await unity.setGDPRConsent(hasGdprConsent);
          debugPrint('Unity GDPR 동의: $hasGdprConsent');
        }
        if (hasCcpaConsent != null) {
          await unity.setCCPAConsent(hasCcpaConsent);
          debugPrint('Unity CCPA 동의: $hasCcpaConsent');
        }
        debugPrint('✅ Unity 미디에이션 설정 완료');
      } catch (e) {
        debugPrint('❌ Unity 미디에이션 설정 오류: $e');
      }

      _gdprConsent = hasGdprConsent;
      _ccpaConsent = hasCcpaConsent;
      _isMediationInitialized = true;
      debugPrint('✅ 미디에이션 초기화 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 미디에이션 초기화 전체 오류: $e');
      debugPrint('Stack trace: $stackTrace');
      // 실패해도 앱이 동작하도록 플래그 설정
      _isMediationInitialized = true;
    }
  }

  /// 기본 미디에이션 초기화 (동의 없이 - 비규제 지역용)
  /// GDPR/CCPA 지역이 아닌 경우 또는 동의 상태를 나중에 업데이트할 때 사용
  static Future<void> initializeMediation() {
    return initializeMediationWithConsent(
      hasGdprConsent: null,
      hasCcpaConsent: null,
    );
  }

  /// 미디에이션 동의 상태 업데이트 (동의 폼 완료 후 호출)
  static Future<void> updateMediationConsent({
    required bool hasGdprConsent,
    required bool hasCcpaConsent,
  }) async {
    try {
      // AppLovin 업데이트
      final applovin = GmaMediationApplovin();
      await applovin.setHasUserConsent(hasGdprConsent);
      await applovin.setDoNotSell(!hasCcpaConsent);

      // Unity 업데이트
      final unity = GmaMediationUnity();
      await unity.setGDPRConsent(hasGdprConsent);
      await unity.setCCPAConsent(hasCcpaConsent);

      _gdprConsent = hasGdprConsent;
      _ccpaConsent = hasCcpaConsent;

      debugPrint(
        '✅ 미디에이션 동의 상태 업데이트: GDPR=$hasGdprConsent, CCPA=$hasCcpaConsent',
      );
    } catch (e) {
      debugPrint('❌ 미디에이션 동의 상태 업데이트 오류: $e');
    }
  }

  /// 동의 결과를 미디에이션에 적용
  static Future<void> _applyConsentToMediation(bool hasConsent) async {
    if (!_isMediationInitialized) {
      // 미디에이션이 아직 초기화되지 않았으면 동의 상태와 함께 초기화
      await initializeMediationWithConsent(
        hasGdprConsent: hasConsent,
        hasCcpaConsent: hasConsent,
      );
    } else {
      // 이미 초기화되었으면 동의 상태만 업데이트
      await updateMediationConsent(
        hasGdprConsent: hasConsent,
        hasCcpaConsent: hasConsent,
      );
    }
    debugPrint('미디에이션에 동의 결과 적용: $hasConsent');
  }

  /// 미디에이션 초기화 상태 확인
  static bool get isMediationInitialized => _isMediationInitialized;

  /// 현재 GDPR 동의 상태
  static bool? get gdprConsent => _gdprConsent;

  /// 현재 CCPA 동의 상태
  static bool? get ccpaConsent => _ccpaConsent;

  /// 미디에이션 재초기화 (필요시 사용)
  static void resetMediation() {
    _isMediationInitialized = false;
    _gdprConsent = null;
    _ccpaConsent = null;
    debugPrint('미디에이션 상태 재설정됨');
  }

  /// AdMob 동의 폼 초기화 및 미디에이션 연동
  /// 동의 폼 결과를 AppLovin/Unity 미디에이션에 전달하고 광고 요청 가능 여부를 반환
  ///
  /// 이름 있는 인자는 테스트 seam 이다. 운영 코드는 인자 없이 호출한다.
  static Future<bool> initializeAdConsent({
    @visibleForTesting Future<void> Function(ConsentRequestParameters)?
    requestConsentInfoUpdate,
    @visibleForTesting Future<void> Function()? loadAndShowConsentFormIfRequired,
  }) async {
    if (!isPlatformAdMobConfigured) {
      debugPrint('AdMob consent skipped: platform ad ids are not configured.');
      privacyOptionsRequired.value = false;
      return false;
    }

    debugPrint('🔧 AdMob 동의 폼 초기화 시작...');

    final params = ConsentRequestParameters();

    try {
      await (requestConsentInfoUpdate ?? _requestConsentInfoUpdate)(params);
      await (loadAndShowConsentFormIfRequired ??
          _loadAndShowConsentFormIfRequired)();
    } catch (error) {
      // 동의 수집에 실패해도 이전 세션에서 얻어 둔 동의 상태는 그대로 확인한다.
      debugPrint('광고 동의 초기화 오류: $error');
    }

    final hasConsent = await _syncConsentState();
    debugPrint('광고 요청 가능: $_hasConsentToRequestAds (미디에이션 동의: $hasConsent)');
    return _hasConsentToRequestAds;
  }

  /// 설정 > 개인정보 선택 항목에서 동의를 다시 조정한다.
  static Future<void> showPrivacyOptionsForm() async {
    try {
      FormError? dismissalError;
      await ConsentForm.showPrivacyOptionsForm((formError) {
        dismissalError = formError;
      });
      if (dismissalError != null) {
        debugPrint(
          '개인정보 옵션 폼 오류: ${dismissalError!.errorCode} - '
          '${dismissalError!.message}',
        );
      }
    } catch (error) {
      debugPrint('개인정보 옵션 폼 표시 오류: $error');
    }

    await _syncConsentState();

    // 사용자가 개인정보 옵션에서 동의를 다시 허용했다면 이번 세션에서도
    // 광고가 동작하도록 SDK를 초기화한다(이전에는 앱 재시작 전까지 막혀 있었다).
    if (_hasConsentToRequestAds && !_isMobileAdsInitialized) {
      await initializeMobileAds();
    }
  }

  /// 최신 동의 상태를 읽어 미디에이션에 반영하고 미디에이션 동의 여부를 반환한다.
  static Future<bool> _syncConsentState() async {
    try {
      _hasConsentToRequestAds = await ConsentInformation.instance
          .canRequestAds();
    } catch (error) {
      debugPrint('광고 요청 가능 여부 확인 오류: $error');
      _hasConsentToRequestAds = false;
    }

    ConsentStatus? status;
    try {
      status = await ConsentInformation.instance.getConsentStatus();
    } catch (error) {
      debugPrint('광고 동의 상태 확인 오류: $error');
    }

    final hasConsent =
        status == ConsentStatus.notRequired ||
        (status == ConsentStatus.obtained && _hasConsentToRequestAds);
    await _applyConsentToMediation(hasConsent);
    await _refreshPrivacyOptionsRequirement();
    return hasConsent;
  }

  static Future<void> _refreshPrivacyOptionsRequirement() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      privacyOptionsRequired.value = false;
      debugPrint('개인정보 옵션 상태 확인 오류: $error');
    }
  }

  static Future<void> _requestConsentInfoUpdate(
    ConsentRequestParameters params,
  ) {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    return completer.future;
  }

  static Future<void> _loadAndShowConsentFormIfRequired() async {
    FormError? dismissalError;
    await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      dismissalError = formError;
    });
    if (dismissalError != null) {
      throw StateError(
        '동의 폼 표시 오류: ${dismissalError!.errorCode} - ${dismissalError!.message}',
      );
    }
  }

  /// UMP가 광고 요청을 허용하고 ATT 처리가 끝난 뒤 SDK를 한 번만 시작한다.
  static Future<void> initializeMobileAds() async {
    if (_isMobileAdsInitialized) {
      _settleMobileAdsGate();
      return;
    }
    if (!isPlatformAdMobConfigured || !_hasConsentToRequestAds) {
      debugPrint('⛔ 사용자 동의가 없어 Google Mobile Ads 초기화를 건너뜁니다.');
      _settleMobileAdsGate();
      return;
    }

    try {
      final status = await MobileAds.instance.initialize();
      status.adapterStatuses.forEach((key, value) {
        debugPrint('Adapter status for $key: ${value.description}');
      });
      _isMobileAdsInitialized = true;
      debugPrint('✅ Google Mobile Ads SDK 초기화 완료');
    } catch (e) {
      debugPrint('❌ Google Mobile Ads SDK 초기화 실패: $e');
    } finally {
      // 성공·실패와 무관하게 게이트를 닫아 대기 중인 광고 위젯을 풀어 준다.
      _settleMobileAdsGate();
    }
  }

  /// ATT 권한 요청 (iOS 전용)
  /// UMP 동의가 광고 요청을 허용한 뒤에만 호출한다.
  static Future<void> requestAttIfNeeded() async {
    if (!Platform.isIOS || !isPlatformAdMobConfigured) return;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;

      // Guideline 5.1.1 — 시스템 팝업 전에 추적이 왜 필요한지 먼저 설명한다.
      await _showAttExplainerDialog();

      // 첫 프레임 직후 시스템 팝업을 안정적으로 표시할 수 있도록 잠시 기다린다.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final result =
          await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('ATT 결과: $result');
    } catch (e) {
      debugPrint('ATT 요청 오류: $e');
    }
  }

  /// ATT 사전 설명(Pre-ATT Explainer) 다이얼로그.
  /// 첫 프레임 이후에 호출되므로 Get.context(Navigator 포함)를 사용할 수 있다.
  /// Navigator가 아직 없으면 설명 없이 시스템 팝업으로 진행한다(요청 자체는 보장).
  static Future<void> _showAttExplainerDialog() async {
    if (Get.context == null) return;
    try {
      await Get.dialog<void>(
        CupertinoAlertDialog(
          title: Text('att_title'.tr),
          content: Text('att_content'.tr),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Get.back<void>(),
              child: Text('att_action'.tr),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      debugPrint('ATT explainer dialog skipped: $e');
    }
  }

  @visibleForTesting
  static void resetInitializationStateForTest() {
    platformAdMobConfiguredOverride = null;
    mobileAdsInitializedOverride = null;
    _hasConsentToRequestAds = false;
    _isMobileAdsInitialized = false;
    _mobileAdsReady = Completer<void>();
    privacyOptionsRequired.value = false;
    bannerAdLoaded.value = false;
    nativeAdLoaded.value = false;
    resetMediation();
  }

  /// 테스트에서 광고 요청 게이트를 열어 둔다.
  /// [mobileAdsReady] 를 즉시 완료시켜 `await` 가 걸리지 않게 한다.
  @visibleForTesting
  static void openAdGateForTest({bool platformConfigured = true}) {
    platformAdMobConfiguredOverride = platformConfigured;
    mobileAdsInitializedOverride = true;
    _settleMobileAdsGate();
  }
}
