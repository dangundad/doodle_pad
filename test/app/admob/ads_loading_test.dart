import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/admob/ads_rewarded.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adsChannel = MethodChannel('plugins.flutter.io/google_mobile_ads');

  setUp(() {
    AdHelper.resetInitializationStateForTest();
    AdHelper.debugModeOverride = false;
    AdHelper.targetPlatformOverride = TargetPlatform.android;
    AdHelper.releaseBannerAdUnitIdAndroidOverride = '';
    AdHelper.releaseInterstitialAdUnitIdAndroidOverride = '';
    AdHelper.releaseRewardedAdUnitIdAndroidOverride = '';
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(adsChannel, null);
  });

  test(
    'interstitial load skips plugin request when release ad unit id is empty',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];

      messenger.setMockMethodCallHandler(adsChannel, (call) async {
        calls.add(call.method);
        return null;
      });

      final manager = InterstitialAdManager();
      await manager.loadAd();

      expect(calls, isEmpty);
      expect(manager.isAdReady.value, isFalse);
    },
  );

  test(
    'rewarded load skips plugin request when release ad unit id is empty',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];

      messenger.setMockMethodCallHandler(adsChannel, (call) async {
        calls.add(call.method);
        return null;
      });

      final manager = RewardedAdManager();
      await manager.loadAd();

      expect(calls, isEmpty);
      expect(manager.isAdReady.value, isFalse);
    },
  );

  testWidgets(
    'banner widget skips plugin request when release ad unit id is empty',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];

      messenger.setMockMethodCallHandler(adsChannel, (call) async {
        calls.add(call.method);
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BannerAdWidget(
            adUnitId: AdHelper.bannerAdUnitId,
            type: AdHelper.banner,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    },
  );
}
