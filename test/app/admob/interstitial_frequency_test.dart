import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_interstitial.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import '../helpers/fake_purchase_service.dart';

/// 전면 광고 빈도 제한.
///
/// 노출 지점은 "작품 저장 / 갤러리 저장 완료" 뿐이고, 그 위에 다음 제한이 걸린다.
/// - 첫 저장([milestonesBeforeFirstAd]회)은 광고 없이 지나간다
/// - 앱 실행당 [maxShowsPerSession]회까지
/// - 직전 노출로부터 [minShowInterval] 경과 후
///
/// 광고 SDK 를 단위 테스트에서 띄울 수는 없으므로, 여기서는 "지금 띄워도 되는
/// 상태인가"([canShowNow])와 카운터 전이만 검증한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InterstitialAdManager manager;
  late DateTime now;

  setUp(() {
    Get.testMode = true;
    Get.put<PurchaseService>(FakePurchaseService(), permanent: true);
    now = DateTime(2026, 9, 17, 12);
    manager = InterstitialAdManager();
    manager.resetFrequencyStateForTest();
    manager.nowFn = () => now;
  });

  tearDown(Get.reset);

  /// 광고가 준비되지 않은 상태에서 마일스톤만 올린다.
  /// (실제 show() 는 SDK 가 필요하므로 카운터 전이만 본다.)
  Future<void> reachMilestone() => manager.notifyMilestoneReached();

  test('첫 저장은 광고 없이 지나간다', () async {
    expect(manager.canShowNow, isFalse, reason: '마일스톤 0회에서는 띄우지 않는다.');

    await reachMilestone();
    expect(manager.milestoneCountForTest, 1);
    expect(
      manager.canShowNow,
      isFalse,
      reason: '첫 저장 직후에는 아직 띄우지 않는다.',
    );
  });

  test('두 번째 저장부터 노출 후보가 된다', () async {
    await reachMilestone();
    await reachMilestone();

    expect(manager.milestoneCountForTest, 2);
    expect(manager.canShowNow, isTrue);
  });

  test('프리미엄 사용자에게는 노출하지 않는다', () async {
    await reachMilestone();
    await reachMilestone();
    expect(manager.canShowNow, isTrue);

    (PurchaseService.to as FakePurchaseService).isPremium.value = true;
    expect(manager.canShowNow, isFalse);
  });

  test('노출 직후에는 최소 간격이 지나기 전까지 다시 띄우지 않는다', () async {
    await reachMilestone();
    await reachMilestone();
    expect(manager.canShowNow, isTrue);

    // 노출이 일어난 상황을 흉내낸다.
    manager.markShownForTest();
    expect(manager.canShowNow, isFalse);

    // 최소 간격 직전
    now = now.add(
      InterstitialAdManager.minShowInterval - const Duration(seconds: 1),
    );
    expect(manager.canShowNow, isFalse);

    // 최소 간격 경과
    now = now.add(const Duration(seconds: 2));
    expect(manager.canShowNow, isTrue);
  });

  test('앱 실행당 최대 노출 횟수를 넘지 않는다', () async {
    await reachMilestone();
    await reachMilestone();

    for (var i = 0; i < InterstitialAdManager.maxShowsPerSession; i++) {
      expect(manager.canShowNow, isTrue, reason: '${i + 1}번째 노출은 허용되어야 한다.');
      manager.markShownForTest();
      now = now.add(
        InterstitialAdManager.minShowInterval + const Duration(seconds: 1),
      );
    }

    expect(
      manager.canShowNow,
      isFalse,
      reason: '상한을 넘으면 간격이 충분해도 더 띄우지 않는다.',
    );
    expect(manager.shownCountForTest, InterstitialAdManager.maxShowsPerSession);
  });

  test('광고가 준비되지 않았으면 노출 카운터가 오르지 않는다', () async {
    await reachMilestone();
    await reachMilestone();
    // 광고 인스턴스가 없으므로 show 가 일어나지 않는다.
    expect(manager.shownCountForTest, 0);
  });
}
