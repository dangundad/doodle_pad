// ================================================
// DangunDad Flutter App - ads_banner.dart Template
// ================================================
// Adaptive 배너 광고 위젯 (mbti_pro 패턴)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_helper.dart';

class BannerAdWidget extends StatefulWidget {
  final String type;
  final String adUnitId;

  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    required this.type,
  });

  @override
  BannerAdState createState() => BannerAdState();
}

class BannerAdState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    if (_bannerAd != null) {
      final oldAd = _bannerAd;
      _bannerAd = null;
      _isLoaded = false;
      _updateAdLoadedState(false);
      await oldAd?.dispose();
    }

    if (!mounted) return;

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        );

    final adSize = size ?? AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (ad != _bannerAd) return;
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _updateAdLoadedState(true);
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('${widget.type} BannerAd failed to load: $error');
          if (ad != _bannerAd) return;
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _updateAdLoadedState(false);
            });
          }
        },
      ),
    );

    return _bannerAd?.load();
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
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
