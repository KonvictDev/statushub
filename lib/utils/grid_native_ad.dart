import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'native_ad_cache.dart';

class GridNativeAd extends StatelessWidget {
  final int index;
  const GridNativeAd({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    NativeAdCache.load(index);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 110, // ✅ perfect native height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: NativeAdCache.isLoaded(index)
            ? AdWidget(ad: NativeAdCache.get(index)!)
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey.shade200,
      child: const Text(
        "Sponsored",
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
