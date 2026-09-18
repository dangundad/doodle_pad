import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;

import 'package:doodle_pad/app/admob/ads_app_open.dart';
import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/admob/ads_native.dart';
import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import '../helpers/fake_purchase_service.dart';

/// 광고 요청 게이트 회귀 테스트.
///
/// 어떤 광고든 플랫폼 설정 → UMP 동의 + SDK 초기화(`AdHelper.mobileAdsReady`)
/// → Premium 아님, 세 관문을 모두 통과해야만 플랫폼 채널을 호출해야 한다.
/// 관문 하나라도 막혔는데 채널이 호출되면 정책 위반(무효 트래픽)이나
/// 프리미엄 사용자에게 광고가 새는 회귀다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adsChannelName = 'plugins.flutter.io/google_mobile_ads';

  late List<String> calls;

  void mockAdsChannel() {
    calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(adsChannelName, (message) async {
          final method = _decodeMethodName(message);
          if (method != null) calls.add(method);
          return const StandardMethodCodec().encodeSuccessEnvelope(null);
        });
  }

  setUp(() {
    AdHelper.resetInitializationStateForTest();
    mockAdsChannel();
  });

  tearDown(() {
    AdHelper.resetInitializationStateForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(adsChannelName, null);
  });

  group('플랫폼 광고 설정이 없으면(데스크톱/미설정 릴리스) 아무 요청도 하지 않는다', () {
    test('전면', () async {
      await InterstitialAdManager().loadAd();
      expect(calls, isEmpty);
    });

    test('보상형', () async {
      await RewardedAdManager().loadAd();
      expect(calls, isEmpty);
    });

    test('앱 오프닝', () async {
      await AppOpenAdManager().loadAd();
      expect(calls, isEmpty);
    });

    testWidgets('배너', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: BannerAdWidget(adUnitId: AdHelper.bannerAdUnitId)),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('네이티브', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NativeAdWidget(templateType: TemplateType.small),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });
  });

  group('SDK 초기화가 끝나지 않았으면 게이트에서 대기하고 요청하지 않는다', () {
    setUp(() {
      // 플랫폼은 설정됐지만 mobileAdsReady 가 아직 완료되지 않은 상태.
      AdHelper.platformAdMobConfiguredOverride = true;
    });

    test('전면', () async {
      final manager = InterstitialAdManager();
      // 게이트가 열리지 않으므로 await 가 끝나지 않는다. 진행 기회만 주고 확인한다.
      unawaited(manager.loadAd());
      await Future<void>.delayed(Duration.zero);

      expect(calls, isEmpty);
      expect(manager.isAdReady.value, isFalse);
    });
  });

  group('게이트가 열려도 Premium 사용자에게는 요청하지 않는다', () {
    setUp(() {
      AdHelper.openAdGateForTest();
      Get.reset();
      Get.put<PurchaseService>(
        FakePurchaseService()..isPremium.value = true,
        permanent: true,
      );
      addTearDown(Get.reset);
    });

    test('전면', () async {
      final manager = InterstitialAdManager();
      await manager.loadAd();

      expect(calls, isEmpty, reason: 'Premium 활성 상태에서는 광고 채널 호출이 없어야 한다.');
      expect(manager.isAdReady.value, isFalse);
    });

    test('보상형', () async {
      final manager = RewardedAdManager();
      await manager.loadAd();

      expect(calls, isEmpty, reason: 'Premium 활성 상태에서는 광고 채널 호출이 없어야 한다.');
      expect(manager.isAdReady.value, isFalse);
    });

    test('앱 오프닝', () async {
      final manager = AppOpenAdManager();
      await manager.loadAd();

      expect(calls, isEmpty, reason: 'Premium 활성 상태에서는 광고 채널 호출이 없어야 한다.');
      expect(manager.isAdAvailable, isFalse);
    });

    testWidgets('배너', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: BannerAdWidget(adUnitId: AdHelper.bannerAdUnitId)),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('네이티브', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NativeAdWidget(templateType: TemplateType.small),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });
  });

  group('세 관문을 모두 통과하면 실제로 광고를 요청한다', () {
    setUp(() {
      AdHelper.openAdGateForTest();
      Get.reset();
      Get.put<PurchaseService>(FakePurchaseService(), permanent: true);
      addTearDown(Get.reset);
    });

    test('전면', () async {
      await InterstitialAdManager().loadAd();
      expect(
        calls,
        contains('loadInterstitialAd'),
        reason: '게이트가 열렸는데도 요청하지 않으면 수익이 0이 된다.',
      );
    });

    test('보상형', () async {
      await RewardedAdManager().loadAd();
      expect(calls, contains('loadRewardedAd'));
    });

    test('앱 오프닝', () async {
      await AppOpenAdManager().loadAd();
      expect(calls, contains('loadAppOpenAd'));
    });
  });
}

/// google_mobile_ads 는 자체 MessageCodec(`AdMessageCodec`)을 쓰기 때문에
/// `StandardMethodCodec` 으로 통째로 디코드하면 인자에서 "Message corrupted" 가
/// 난다. 이 테스트가 필요한 정보는 "어떤 메서드가 호출됐는가" 뿐이므로
/// 메서드 이름(선두 문자열)만 직접 읽는다.
String? _decodeMethodName(ByteData? message) {
  if (message == null) return null;
  final bytes = Uint8List.view(
    message.buffer,
    message.offsetInBytes,
    message.lengthInBytes,
  );
  // StandardMessageCodec: 0x07 == valueString
  if (bytes.isEmpty || bytes[0] != 0x07) return null;

  var offset = 1;
  var size = bytes[offset++];
  if (size == 254) {
    size = bytes[offset] | (bytes[offset + 1] << 8);
    offset += 2;
  } else if (size == 255) {
    size =
        bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
    offset += 4;
  }
  if (offset + size > bytes.length) return null;
  return utf8.decode(bytes.sublist(offset, offset + size));
}
