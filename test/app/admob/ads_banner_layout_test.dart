import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import '../helpers/fake_purchase_service.dart';

/// 배너 바 레이아웃 회귀 테스트.
///
/// `AdBannerBar` 는 광고가 없을 때 "자리를 차지하지 않아야" 한다. 이걸 어기면
/// `Scaffold.bottomNavigationBar` 처럼 느슨한(0..maxHeight) 제약을 주는 슬롯에서
/// 바가 화면 전체를 먹고 body 높이가 0이 되어 **화면이 통째로 빈 화면**이 된다.
/// (설정 화면이 실제로 이렇게 사라졌다.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adsChannelName = 'plugins.flutter.io/google_mobile_ads';

  setUp(() {
    AdHelper.resetInitializationStateForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          adsChannelName,
          (message) async =>
              const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
  });

  tearDown(() {
    AdHelper.resetInitializationStateForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(adsChannelName, null);
    Get.reset();
  });

  testWidgets('광고가 없으면 bottomNavigationBar 슬롯에서 높이를 차지하지 않는다', (tester) async {
    AdHelper.platformAdMobConfiguredOverride = true;
    Get.put<PurchaseService>(FakePurchaseService());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(child: Text('body content')),
          bottomNavigationBar: const AdBannerBar(),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byType(AdBannerBar)).height,
      0,
      reason: '광고가 없는 배너 바가 높이를 차지하면 body 가 밀려 사라진다',
    );
    expect(find.text('body content'), findsOneWidget);
    expect(
      tester.getSize(find.byType(Scaffold)).height -
          tester.getSize(find.byType(AppBar)).height,
      greaterThan(0),
    );
    // body 가 실제로 그려질 높이를 받았는지 확인한다.
    final bodyBox = tester.renderObject<RenderBox>(
      find.ancestor(
        of: find.text('body content'),
        matching: find.byType(Center),
      ),
    );
    expect(bodyBox.size.height, greaterThan(100));
  });
}
