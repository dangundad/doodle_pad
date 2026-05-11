// Doodle Pad 공통 배너 광고 위젯.
// UMP 동의(`AdHelper.canRequestAds`)와 Premium 상태(`PurchaseService.isPremiumActive`)를
// 모두 통과한 경우에만 광고를 요청한다.
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
    required this.type,
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
  Worker? _consentWorker;
  Worker? _premiumWorker;
  Worker? _devPremiumWorker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoadStarted) {
      _isLoadStarted = true;
      _scheduleLoadWhenReady();
    }
  }

  @override
  void dispose() {
    _consentWorker?.dispose();
    _premiumWorker?.dispose();
    _devPremiumWorker?.dispose();
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  bool get _isPremiumActive => PurchaseService.isPremiumActive;

  void _scheduleLoadWhenReady() {
    if (_isPremiumActive) {
      _updateAdLoadedState(false);
    } else if (AdHelper.canRequestAds.value) {
      unawaited(_loadBanner());
    } else {
      _consentWorker = ever<bool>(AdHelper.canRequestAds, (canRequest) {
        if (!mounted || !canRequest || _isPremiumActive) return;
        unawaited(_loadBanner());
      });
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
    if (AdHelper.canRequestAds.value && _bannerAd == null) {
      unawaited(_loadBanner());
    }
  }

  Future<void> _loadBanner() async {
    if (_isLoading) return;
    if (_isLoaded && _bannerAd != null) return;
    if (_isPremiumActive) {
      _updateAdLoadedState(false);
      return;
    }
    if (!AdHelper.canRequestAds.value) {
      _updateAdLoadedState(false);
      return;
    }
    if (!AdHelper.hasUsableAdUnitId(widget.adUnitId)) {
      debugPrint(
        '${widget.debugLabel ?? widget.type} BannerAd skipped: release ad unit id is not configured',
      );
      _updateAdLoadedState(false);
      return;
    }

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
