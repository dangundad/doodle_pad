import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import '../helpers/fake_purchase_service.dart';

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
    AdHelper.resetInitializationStateForTest();
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

  test(
    'interstitial load skips plugin request when consent is granted but ad unit id is empty',
    () async {
      AdHelper.canRequestAds.value = true;
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
    'interstitial load skips plugin request when premium is active even with valid ad unit id',
    () async {
      AdHelper.canRequestAds.value = true;
      AdHelper.releaseInterstitialAdUnitIdAndroidOverride =
          'ca-app-pub-test/interstitial';
      Get.reset();
      Get.put<PurchaseService>(
        FakePurchaseService()..isPremium.value = true,
        permanent: true,
      );
      addTearDown(Get.reset);

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];
      messenger.setMockMethodCallHandler(adsChannel, (call) async {
        calls.add(call.method);
        return null;
      });

      final manager = InterstitialAdManager();
      await manager.loadAd();

      expect(calls, isEmpty,
          reason: 'Premium 활성 상태에서는 광고 플랫폼 채널 호출이 발생해서는 안 된다.');
      expect(manager.isAdReady.value, isFalse);
    },
  );

  test(
    'rewarded load skips plugin request when premium is active even with valid ad unit id',
    () async {
      AdHelper.canRequestAds.value = true;
      AdHelper.releaseRewardedAdUnitIdAndroidOverride =
          'ca-app-pub-test/rewarded';
      Get.reset();
      Get.put<PurchaseService>(
        FakePurchaseService()..isPremium.value = true,
        permanent: true,
      );
      addTearDown(Get.reset);

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];
      messenger.setMockMethodCallHandler(adsChannel, (call) async {
        calls.add(call.method);
        return null;
      });

      final manager = RewardedAdManager();
      await manager.loadAd();

      expect(calls, isEmpty,
          reason: 'Premium 활성 상태에서는 광고 플랫폼 채널 호출이 발생해서는 안 된다.');
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
