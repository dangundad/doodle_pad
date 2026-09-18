// 네이티브 고급형(Native Advanced) 광고 위젯.
// 종료 시트처럼 "사용자가 이미 흐름을 마친" 자리에만 배치한다.
// 그리기 캔버스나 작업 도중에는 절대 넣지 않는다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';

import 'ads_helper.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType templateType;

  /// 광고가 **실제로 렌더될 때만** 적용되는 여백.
  /// 호출부에서 `SizedBox` 로 여백을 주면 광고가 없을 때(프리미엄·동의 거부·로드
  /// 실패) 빈 공간만 남는다. 여백을 광고와 함께 접으려면 이 인자를 쓴다.
  final EdgeInsetsGeometry? padding;

  const NativeAdWidget({super.key, required this.templateType, this.padding});

  @override
  State<StatefulWidget> createState() => NativeAdState();
}

class NativeAdState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  Completer<NativeAd?> nativeAdCompleter = Completer<NativeAd?>();
  Worker? _premiumWorker;
  Worker? _devPremiumWorker;

  @override
  void initState() {
    super.initState();

    // 로드 시작 시 상태를 false로 설정 (안전장치)
    AdHelper.nativeAdLoaded.value = false;

    // 구매 완료 즉시 네이티브 광고를 해제해 프리미엄 경험을 보장한다.
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

    unawaited(_loadNativeAd());
  }

  void _handlePremiumChange() {
    if (!PurchaseService.isPremiumActive) return;
    _nativeAd?.dispose();
    _nativeAd = null;
    AdHelper.nativeAdLoaded.value = false;
    if (!mounted) return;
    setState(() {
      // Completer가 완료되지 않았다면 새로 생성해 FutureBuilder가 대기 상태로 초기화되도록 한다.
      if (!nativeAdCompleter.isCompleted) {
        nativeAdCompleter = Completer<NativeAd?>();
      }
    });
  }

  Future<void> _loadNativeAd() async {
    final adUnitId = AdHelper.nativeAdUnitId;
    if (!AdHelper.isPlatformAdMobConfigured ||
        !AdHelper.hasUsableAdUnitId(adUnitId) ||
        PurchaseService.isPremiumActive) {
      if (!nativeAdCompleter.isCompleted) nativeAdCompleter.complete(null);
      return;
    }

    // 광고 초기화는 첫 프레임 이후로 지연되므로 초기화 시도가 끝날 때까지 기다린다.
    await AdHelper.mobileAdsReady;

    // 동의를 얻지 못해 SDK 초기화를 건너뛴 경우 광고를 요청하지 않는다.
    // 프리미엄 사용자이거나 대기 중 화면이 닫혔을 때도 광고를 만들지 않는다.
    if (!mounted ||
        !AdHelper.canRequestAds ||
        PurchaseService.isPremiumActive) {
      if (!nativeAdCompleter.isCompleted) nativeAdCompleter.complete(null);
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('NativeAd loaded.');
          AdHelper.nativeAdLoaded.value = true;
          if (!nativeAdCompleter.isCompleted) {
            nativeAdCompleter.complete(ad as NativeAd);
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('NativeAd failed to load: $error');
          AdHelper.nativeAdLoaded.value = false;
          if (!nativeAdCompleter.isCompleted) {
            nativeAdCompleter.complete(null);
          }
          ad.dispose();
        },
      ),
      request: const AdRequest(),

      // Styling options
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 16.r,
      ),
    );

    unawaited(_nativeAd?.load());
  }

  @override
  void dispose() {
    _premiumWorker?.dispose();
    _devPremiumWorker?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.isPlatformAdMobConfigured) {
      return const SizedBox.shrink();
    }
    // PurchaseService 미등록 단독 테스트에서는 Obx 가 "no observable" 로 실패하므로
    // 등록 여부를 먼저 확인한다(배너 위젯과 같은 규칙).
    if (!Get.isRegistered<PurchaseService>()) {
      return _buildNativeAd();
    }
    return Obx(() {
      // 프리미엄 사용자는 빈 위젯 반환
      if (PurchaseService.isPremiumActive) {
        return const SizedBox.shrink();
      }
      return _buildNativeAd();
    });
  }

  Widget _buildNativeAd() {
    return FutureBuilder<NativeAd?>(
      future: nativeAdCompleter.future,
      builder: (BuildContext context, AsyncSnapshot<NativeAd?> snapshot) {
        final isLoaded =
            snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null &&
            _nativeAd != null;

        // 로드 전에는 공간을 예약하지 않는다 (빈 영역 노출 방지).
        if (!isLoaded) {
          return const SizedBox.shrink();
        }

        final Widget child = ConstrainedBox(
          constraints: widget.templateType == TemplateType.small
              ? const BoxConstraints(
                  minWidth: 320, // minimum recommended width
                  minHeight: 90, // minimum recommended height
                  maxWidth: 400,
                  maxHeight: 200,
                )
              : const BoxConstraints(
                  minWidth: 320, // minimum recommended width
                  minHeight: 320, // minimum recommended height
                  maxWidth: 400,
                  maxHeight: 400,
                ),
          child: AdWidget(ad: _nativeAd!),
        );

        final padding = widget.padding;
        if (padding == null) return child;
        return Padding(padding: padding, child: child);
      },
    );
  }
}
