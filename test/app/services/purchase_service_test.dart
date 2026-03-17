// ignore_for_file: must_call_super

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _FakeInAppPurchasePlatform fakePlatform;

  setUp(() async {
    Get.testMode = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    tempDir = await Directory.systemTemp.createTemp(
      'doodle_pad_purchase_service_test_',
    );
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.SETTINGS_BOX);
    await Hive.openBox(HiveService.APP_DATA_BOX);

    Get.put<HiveService>(HiveService(), permanent: true);
    Get.put<InterstitialAdManager>(_FakeInterstitialAdManager(), permanent: true);
    Get.put<RewardedAdManager>(_FakeRewardedAdManager(), permanent: true);

    fakePlatform = _FakeInAppPurchasePlatform(
      availabilityQueue: <bool>[false, true],
    );
    InAppPurchasePlatform.instance = fakePlatform;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test(
    'restorePurchases retries store initialization after an unavailable first attempt',
    () async {
      final service = PurchaseService();

      await service.initialize();
      expect(service.available.value, isFalse);
      expect(fakePlatform.isAvailableCallCount, 1);

      await service.restorePurchases();

      expect(fakePlatform.isAvailableCallCount, 2);
      expect(service.available.value, isTrue);
      expect(fakePlatform.restorePurchasesCallCount, 1);
    },
  );

  test(
    'initialize clears stale cached premium when store has no active purchases',
    () async {
      await HiveService.to.setSetting(HiveKeys.IS_PREMIUM, true);
      fakePlatform = _FakeInAppPurchasePlatform(
        availabilityQueue: <bool>[true],
      );
      InAppPurchasePlatform.instance = fakePlatform;

      final service = PurchaseService(
        pastPurchasesLoader: () async => <PurchaseDetails>[],
        isAndroidPlatform: () => true,
      );

      await service.initialize();

      expect(service.isPremium.value, isFalse);
      expect(
        HiveService.to.getSetting<bool>(HiveKeys.IS_PREMIUM, defaultValue: true),
        isFalse,
      );
    },
  );

  test(
    'initialize restores premium from active store purchases even when cache is false',
    () async {
      fakePlatform = _FakeInAppPurchasePlatform(
        availabilityQueue: <bool>[true],
      );
      InAppPurchasePlatform.instance = fakePlatform;

      final service = PurchaseService(
        pastPurchasesLoader: () async => <PurchaseDetails>[_activePremiumPurchase],
        isAndroidPlatform: () => true,
      );

      await service.initialize();

      expect(service.isPremium.value, isTrue);
      expect(
        HiveService.to.getSetting<bool>(HiveKeys.IS_PREMIUM, defaultValue: false),
        isTrue,
      );
    },
  );
}

final PurchaseDetails _activePremiumPurchase = PurchaseDetails(
  productID: PurchaseConstants.PREMIUM_MONTHLY_ANDROID,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'server',
    source: 'test',
  ),
  transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
  status: PurchaseStatus.purchased,
);

class _FakeInterstitialAdManager extends InterstitialAdManager {
  @override
  void onInit() {}
}

class _FakeRewardedAdManager extends RewardedAdManager {
  @override
  void onInit() {}
}

class _FakeInAppPurchasePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements InAppPurchasePlatform {
  _FakeInAppPurchasePlatform({
    required List<bool> availabilityQueue,
    Stream<List<PurchaseDetails>>? purchaseStream,
  }) : _availabilityQueue = availabilityQueue,
       _purchaseStream = purchaseStream ?? const Stream<List<PurchaseDetails>>.empty();

  final List<bool> _availabilityQueue;
  final Stream<List<PurchaseDetails>> _purchaseStream;

  int isAvailableCallCount = 0;
  int restorePurchasesCallCount = 0;

  @override
  Future<bool> isAvailable() async {
    isAvailableCallCount++;
    if (_availabilityQueue.isEmpty) {
      return true;
    }
    return _availabilityQueue.removeAt(0);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseStream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return Future<ProductDetailsResponse>.value(
      ProductDetailsResponse(
        productDetails: <ProductDetails>[],
        notFoundIDs: <String>[],
      ),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) {
    return Future<bool>.value(true);
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) {
    return Future<bool>.value(true);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return Future<void>.value();
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) {
    restorePurchasesCallCount++;
    return Future<void>.value();
  }

  @override
  Future<String> countryCode() {
    return Future<String>.value('KR');
  }
}
