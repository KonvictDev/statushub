import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';

class NativeAdWidget extends StatefulWidget {
  final bool isSmall;
  const NativeAdWidget({super.key, this.isSmall = false});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'listTile', // Ensure this matches your Android/iOS native setup
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native Ad failed to load: $error');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.isSmall ? TemplateType.small : TemplateType.medium,
        mainBackgroundColor: Colors.white10,
        cornerRadius: 16.0,
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      height: widget.isSmall ? 90 : 320,
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}