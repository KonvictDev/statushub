import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';

class NativeAdCache {
  static final Map<int, NativeAd> _ads = {};
  static final Map<int, bool> _loaded = {};

  static void load(int index) {
    if (_ads.containsKey(index)) return;

    final ad = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        cornerRadius: 16,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _loaded[index] = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loaded[index] = false;
        },
      ),
    );

    ad.load();
    _ads[index] = ad;
  }

  static NativeAd? get(int index) => _ads[index];
  static bool isLoaded(int index) => _loaded[index] == true;

  static void disposeAll() {
    for (final ad in _ads.values) {
      ad.dispose();
    }
    _ads.clear();
    _loaded.clear();
  }
}
