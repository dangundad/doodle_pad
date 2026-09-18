// Doodle Pad 공통 배너 광고 위젯.
// 플랫폼 광고 설정(`AdHelper.isPlatformAdMobConfigured`), UMP 동의 + SDK 초기화
// (`AdHelper.mobileAdsReady` → `AdHelper.canRequestAds`), Premium 상태
// (`PurchaseService.isPremiumActive`)를 모두 통과한 경우에만 광고를 요청한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/purchase_service.dart';
import 'ads_helper.dart';

enum BannerType { standard, adaptive }

class BannerAdWidget extends StatefulWidget {
  final String adUnitId;
  final String type;
  final BannerType bannerType;
  final String? debugLabel;

  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    this.type = AdHelper.banner,
    this.bannerType = BannerType.adaptive,
    this.debugLabel,
  });

  @override
  BannerAdState createState() => BannerAdState();
}

class BannerAdState extends State<BannerAdWidget> {
  static const List<Duration> _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  BannerAd? _bannerAd;
  AdSize? _targetAdSize;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isLoadStarted = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  Worker? _premiumWorker;
  Worker? _devPremiumWorker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoadStarted) {
      _isLoadStarted = true;
      _startLoad();
    }
  }

  @override
  void dispose() {
    _premiumWorker?.dispose();
    _devPremiumWorker?.dispose();
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  bool get _isPremiumActive => PurchaseService.isPremiumActive;

  void _startLoad() {
    if (!_isPremiumActive) {
      unawaited(_loadBanner());
    } else {
      _updateAdLoadedState(false);
    }

    // PurchaseService 가 등록된 경우에만 Premium 전환을 감지한다.
    // 위젯 단독 테스트처럼 미등록 상태에서는 광고 동작만 검증한다.
    if (Get.isRegistered<PurchaseService>()) {
      final purchase = PurchaseService.to;
      _premiumWorker = ever<bool>(
        purchase.isPremium,
        (_) => _handlePremiumChange(),
      );
      _devPremiumWorker = ever<bool>(
        purchase.isDevPremium,
        (_) => _handlePremiumChange(),
      );
    }
  }

  void _handlePremiumChange() {
    if (!mounted) return;
    if (_isPremiumActive) {
      _disposeBanner();
      return;
    }
    if (_bannerAd == null) unawaited(_loadBanner());
  }

  Future<void> _loadBanner() async {
    if (_isLoading) return;
    if (_isLoaded && _bannerAd != null) return;
    if (_isPremiumActive) {
      _updateAdLoadedState(false);
      return;
    }
    // 광고를 지원하지 않는 플랫폼/미설정 빌드에서는 게이트를 기다리지도 않는다.
    if (!AdHelper.isPlatformAdMobConfigured ||
        !AdHelper.hasUsableAdUnitId(widget.adUnitId)) {
      debugPrint(
        '${widget.debugLabel ?? widget.type} BannerAd skipped: ad unit id is not configured',
      );
      _updateAdLoadedState(false);
      return;
    }

    _isLoading = true;

    // 광고 초기화는 첫 프레임 이후로 지연되므로 초기화 시도가 끝날 때까지 기다린다.
    await AdHelper.mobileAdsReady;

    // 동의를 얻지 못해 SDK 초기화를 건너뛴 경우 광고를 요청하지 않는다.
    if (!mounted || !AdHelper.canRequestAds || _isPremiumActive) {
      _isLoading = false;
      _updateAdLoadedState(false);
      return;
    }

    // 재시도 진입 시 남아 있을 수 있는 이전 인스턴스를 정리한다.
    // `_disposeBanner` 가 `_isLoading` 을 내리므로 이후 다시 올린다.
    _disposeBanner(updateState: false);
    if (!mounted) return;
    _isLoading = true;

    late final AdSize adSize;
    if (widget.bannerType == BannerType.adaptive) {
      final mediaQuery = MediaQuery.of(context);
      final AnchoredAdaptiveBannerAdSize? size =
          // ignore: deprecated_member_use
          await AdSize.getAnchoredAdaptiveBannerAdSize(
            mediaQuery.orientation,
            mediaQuery.size.width.truncate(),
          );

      if (size == null) {
        debugPrint(
          'Unable to get adaptive banner size, falling back to standard banner.',
        );
        adSize = AdSize.banner;
      } else {
        adSize = size;
      }
    } else {
      adSize = AdSize.banner;
    }

    if (!mounted || _isPremiumActive) {
      _isLoading = false;
      return;
    }
    _targetAdSize = adSize;
    setState(() {});

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) async {
          debugPrint('${widget.debugLabel ?? widget.type} BannerAd loaded.');
          if (_isPremiumActive) {
            ad.dispose();
            _isLoading = false;
            _bannerAd = null;
            _updateAdLoadedState(false);
            if (mounted) setState(() => _isLoaded = false);
            return;
          }

          AdSize? platformSize;
          try {
            platformSize = await (ad as BannerAd).getPlatformAdSize();
          } catch (_) {
            platformSize = null;
          }
          if (!mounted) return;

          _isLoading = false;
          _retryAttempt = 0;
          _updateAdLoadedState(true);
          setState(() {
            _isLoaded = true;
            if (platformSize != null) _targetAdSize = platformSize;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _isLoading = false;
          ad.dispose();
          _bannerAd = null;
          debugPrint(
            '${widget.debugLabel ?? widget.type} BannerAd failed to load: $error',
          );
          _updateAdLoadedState(false);
          if (mounted) setState(() => _isLoaded = false);
          _scheduleRetry();
        },
      ),
    );

    return _bannerAd?.load();
  }

  void _scheduleRetry() {
    if (!mounted || _isPremiumActive) return;

    final delay = _retryDelays[_retryAttempt.clamp(0, _retryDelays.length - 1)];
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted || _isPremiumActive) return;
      unawaited(_loadBanner());
    });
  }

  void _disposeBanner({bool updateState = true}) {
    _retryTimer?.cancel();
    _retryTimer = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    _targetAdSize = null;
    _isLoaded = false;
    _isLoading = false;
    _updateAdLoadedState(false);
    if (updateState && mounted) setState(() {});
  }

  void _updateAdLoadedState(bool isLoaded) {
    switch (widget.type) {
      case AdHelper.banner:
        AdHelper.bannerAdLoaded.value = isLoaded;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium 변화는 worker 가 `_disposeBanner` → `setState` 로 반영하므로
    // build 단계에서 Rx 를 직접 구독할 필요는 없다. Obx 로 감싸면 PurchaseService
    // 미등록 단독 테스트에서 "no observable" 오류가 발생한다.
    if (_isPremiumActive || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final fallbackHeight = AdSize.banner.height.toDouble();
    final actual = _targetAdSize ?? _bannerAd!.size;
    final actualHeight = actual.height > 0
        ? actual.height.toDouble()
        : fallbackHeight;
    return SizedBox(
      width: actual.width.toDouble(),
      height: actualHeight,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// 페이지 하단 고정 배너 바.
/// 홈·설정·프리미엄이 같은 배너 하나를 공유한다.
/// 프리미엄 사용자에게는 어떤 공간도 차지하지 않도록 완전히 숨긴다.
class AdBannerBar extends StatelessWidget {
  const AdBannerBar({super.key, this.safeArea = true});

  /// 화면 최하단이 아니라 다른 고정 바(예: 프리미엄 구매 바) 위에 놓일 때는
  /// false 로 둔다. true 로 두면 아래쪽 제스처 바 여백이 이중으로 붙는다.
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.isPlatformAdMobConfigured) {
      return const SizedBox.shrink();
    }
    if (!Get.isRegistered<PurchaseService>()) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      if (PurchaseService.isPremiumActive) {
        return const SizedBox.shrink();
      }
      // heightFactor 를 비우면 Center 가 "느슨한" 제약(0..maxHeight)을 가득
      // 채운다. `Scaffold.bottomNavigationBar` 슬롯이 바로 그런 제약을 주기
      // 때문에, 광고가 아직 없을 때(=자식 높이 0) 바가 화면 전체를 먹고
      // body 높이가 0이 되어 화면이 통째로 비어 버린다(설정 화면 실제 사례).
      // heightFactor: 1 로 항상 자식 높이만큼만 차지하게 고정한다.
      final banner = Center(
        heightFactor: 1,
        child: BannerAdWidget(adUnitId: AdHelper.bannerAdUnitId),
      );
      if (!safeArea) return banner;
      return SafeArea(top: false, child: banner);
    });
  }
}
