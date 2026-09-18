import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/admob/ads_helper.dart';

/// Doodle Pad AdMob 퍼블리셔 ID (AndroidManifest의 앱 ID와 같아야 한다).
const _doodlePadPublisher = '9645460570589541';

/// Google 공식 샘플(테스트) 퍼블리셔 ID.
const _googleSamplePublisher = '3940256099942544';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const umpChannel = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');
  const appLovinConsentChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.gma_mediation_applovin.AppLovinSDKApi.setHasUserConsent',
    StandardMessageCodec(),
  );
  const appLovinDoNotSellChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.gma_mediation_applovin.AppLovinSDKApi.setDoNotSell',
    StandardMessageCodec(),
  );
  const unityGdprChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.gma_mediation_unity.UnityPrivacyApi.setGDPRConsent',
    StandardMessageCodec(),
  );
  const unityCcpaChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.gma_mediation_unity.UnityPrivacyApi.setCCPAConsent',
    StandardMessageCodec(),
  );

  setUp(() {
    AdHelper.resetInitializationStateForTest();
  });

  tearDown(() {
    AdHelper.resetInitializationStateForTest();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(umpChannel, null);
    for (final channel in [
      appLovinConsentChannel,
      appLovinDoNotSellChannel,
      unityGdprChannel,
      unityCcpaChannel,
    ]) {
      messenger.setMockDecodedMessageHandler<Object?>(channel, null);
    }
  });

  test(
    'initializeAdConsent forwards obtained consent to mediation SDKs',
    () async {
      // 테스트 호스트(데스크톱)에서는 광고 게이트가 닫혀 있으므로 강제로 연다.
      AdHelper.platformAdMobConfiguredOverride = true;

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];

      messenger.setMockMethodCallHandler(umpChannel, (call) async {
        switch (call.method) {
          case 'ConsentInformation#canRequestAds':
            calls.add('canRequestAds');
            return true;
          case 'ConsentInformation#getConsentStatus':
            calls.add('getConsentStatus');
            return 3; // ConsentStatus.obtained
          case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
            calls.add('getPrivacyOptionsRequirementStatus');
            return 1; // required
        }
        fail('Unexpected UMP call: ${call.method}');
      });
      messenger.setMockDecodedMessageHandler<Object?>(appLovinConsentChannel, (
        message,
      ) async {
        calls.add('appLovin:${(message as List<Object?>).single}');
        return <Object?>[];
      });
      messenger.setMockDecodedMessageHandler<Object?>(
        appLovinDoNotSellChannel,
        (message) async => <Object?>[],
      );
      messenger.setMockDecodedMessageHandler<Object?>(unityGdprChannel, (
        message,
      ) async {
        calls.add('unity:${(message as List<Object?>).single}');
        return <Object?>[];
      });
      messenger.setMockDecodedMessageHandler<Object?>(
        unityCcpaChannel,
        (message) async => <Object?>[],
      );

      final canRequestAds = await AdHelper.initializeAdConsent(
        requestConsentInfoUpdate: (_) async {},
        loadAndShowConsentFormIfRequired: () async {},
      );

      expect(canRequestAds, isTrue);
      expect(
        calls,
        containsAllInOrder(['canRequestAds', 'getConsentStatus', 'appLovin:true']),
      );
      expect(calls, contains('unity:true'));
      expect(
        AdHelper.privacyOptionsRequired.value,
        isTrue,
        reason: '동의 폼을 다시 열 수 있어야 설정에서 개인정보 옵션을 노출할 수 있다.',
      );

      // UMP 동의만으로는 광고를 요청하지 않는다. SDK 초기화까지 끝나야 한다.
      expect(
        AdHelper.canRequestAds,
        isFalse,
        reason: 'MobileAds.initialize 전에는 광고를 요청해서는 안 된다.',
      );
    },
  );

  test('동의를 얻지 못하면 광고 요청 게이트가 열리지 않는다', () async {
    AdHelper.platformAdMobConfiguredOverride = true;

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(umpChannel, (call) async {
      switch (call.method) {
        case 'ConsentInformation#canRequestAds':
          return false;
        case 'ConsentInformation#getConsentStatus':
          return 1; // required (아직 동의하지 않음)
        case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
          return 0; // notRequired
      }
      fail('Unexpected UMP call: ${call.method}');
    });
    for (final channel in [
      appLovinConsentChannel,
      appLovinDoNotSellChannel,
      unityGdprChannel,
      unityCcpaChannel,
    ]) {
      messenger.setMockDecodedMessageHandler<Object?>(
        channel,
        (message) async => <Object?>[],
      );
    }

    final canRequestAds = await AdHelper.initializeAdConsent(
      requestConsentInfoUpdate: (_) async {},
      loadAndShowConsentFormIfRequired: () async {},
    );

    expect(canRequestAds, isFalse);
    expect(AdHelper.canRequestAds, isFalse);
  });

  test('광고를 지원하지 않는 플랫폼에서는 광고를 요청하지 않는다', () {
    // 테스트 호스트(데스크톱)는 Android/iOS가 아니므로 광고가 완전히 꺼진다.
    expect(AdHelper.isPlatformAdMobConfigured, isFalse);
    expect(AdHelper.canRequestAds, isFalse);
  });

  test('디버그 빌드는 Google 샘플 테스트 광고 ID만 사용한다', () {
    // flutter test는 항상 kDebugMode이므로, 실 광고 ID가 테스트/디버그 경로로
    // 새어 나오면 여기서 잡힌다(정책 위반 계정 정지 예방).
    for (final id in [
      AdHelper.bannerAdUnitId,
      AdHelper.interstitialAdUnitId,
      AdHelper.nativeAdUnitId,
      AdHelper.appOpenAdUnitId,
      AdHelper.rewardedAdUnitId,
    ]) {
      expect(id, startsWith('ca-app-pub-$_googleSamplePublisher/'), reason: id);
    }
  });

  test('ads_helper의 광고 ID 리터럴은 형식과 퍼블리셔가 올바르다', () {
    final source = File('lib/app/admob/ads_helper.dart').readAsStringSync();
    final ids = RegExp(
      r'ca-app-pub-\d+[/~]\d+',
    ).allMatches(source).map((match) => match.group(0)!).toSet();

    expect(ids, isNotEmpty);
    for (final id in ids) {
      expect(
        RegExp(r'^ca-app-pub-\d{16}[/~]\d{10}$').hasMatch(id),
        isTrue,
        reason: '광고 ID 형식이 올바르지 않습니다: $id',
      );
      final publisher = id.substring('ca-app-pub-'.length, id.length - 11);
      expect(
        publisher,
        anyOf(_doodlePadPublisher, _googleSamplePublisher),
        reason: '알 수 없는 퍼블리셔 ID: $id',
      );
    }
  });

  test('릴리스 Android 광고 단위 ID가 슬롯별로 모두 다르다', () {
    // 복사-붙여넣기로 두 슬롯이 같은 ID를 쓰면 한쪽 지면의 수익이 통째로 사라진다.
    final source = File('lib/app/admob/ads_helper.dart').readAsStringSync();
    final realIds = RegExp('ca-app-pub-$_doodlePadPublisher/\\d{10}')
        .allMatches(source)
        .map((match) => match.group(0)!)
        .toList();

    expect(realIds, isNotEmpty);
    // 배너·전면·네이티브·앱오프닝·보상형 5종 (주석 블록 + getter 본문에 중복 등장)
    expect(realIds.toSet().length, 5, reason: '고유 실 광고 단위는 5개여야 한다: $realIds');
  });

  test('AndroidManifest의 AdMob 앱 ID는 광고 단위와 같은 퍼블리셔를 쓴다', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final appId = RegExp(
      r'ca-app-pub-\d{16}~\d{10}',
    ).firstMatch(manifest)?.group(0);

    expect(appId, isNotNull, reason: 'AndroidManifest에 AdMob 앱 ID가 없습니다.');
    expect(appId, startsWith('ca-app-pub-$_doodlePadPublisher~'));

    // ads_helper 주석에 기록된 앱 ID와도 일치해야 한다.
    final source = File('lib/app/admob/ads_helper.dart').readAsStringSync();
    expect(source, contains(appId!));
  });
}
