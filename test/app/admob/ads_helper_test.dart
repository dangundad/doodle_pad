import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/admob/ads_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const umpChannel = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');
  const appLovinConsentChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.gma_mediation_applovin.AppLovinSDKApi.setHasUserConsent',
    StandardMessageCodec(),
  );
  const unityGdprChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.gma_mediation_unity.UnityPrivacyApi.setGDPRConsent',
    StandardMessageCodec(),
  );

  setUp(() {
    AdHelper.resetInitializationStateForTest();
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(umpChannel, null);
    messenger.setMockDecodedMessageHandler<Object?>(appLovinConsentChannel, null);
    messenger.setMockDecodedMessageHandler<Object?>(unityGdprChannel, null);
  });

  test(
    'initializeConsentAndAds forwards obtained consent to mediation SDKs before ads init',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];

      messenger.setMockMethodCallHandler(umpChannel, (call) async {
        if (call.method == 'ConsentInformation#getConsentStatus') {
          calls.add('getConsentStatus');
          return 3;
        }
        fail('Unexpected UMP call: ${call.method}');
      });
      messenger.setMockDecodedMessageHandler<Object?>(
        appLovinConsentChannel,
        (message) async {
          calls.add('appLovin:${(message as List<Object?>).single}');
          return <Object?>[];
        },
      );
      messenger.setMockDecodedMessageHandler<Object?>(
        unityGdprChannel,
        (message) async {
          calls.add('unity:${(message as List<Object?>).single}');
          return <Object?>[];
        },
      );

      await AdHelper.initializeConsentAndAds(
        requestTrackingAuthorizationIfNeeded: () async {},
        requestConsentInfoUpdate: () async {},
        loadAndShowConsentFormIfRequired: () async {},
        canRequestAds: () async => true,
        initializeMobileAds: () async {
          calls.add('initializeMobileAds');
        },
      );

      expect(
        calls,
        containsAllInOrder([
          'getConsentStatus',
          'appLovin:true',
          'unity:true',
          'initializeMobileAds',
        ]),
      );
    },
  );
}
