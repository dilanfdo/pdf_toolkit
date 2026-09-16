import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralizes AdMob unit IDs and interstitial frequency capping.
///
/// IMPORTANT: these are Google's official *test* ad unit IDs. Swap them for
/// real ad unit IDs (via --dart-define or a build-time config) before a
/// release build ships to the store — test IDs must never go to production.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _exportCounterKey = 'export_count_since_last_ad';
  static const _exportsPerInterstitial = 3;

  Future<void> initialize() => MobileAds.instance.initialize();

  String get bannerAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  String get interstitialAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  BannerAd createBannerAd({required void Function(Ad ad) onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  /// Call after a successful export. Shows an interstitial at most once
  /// every [_exportsPerInterstitial] exports, and never on the first one.
  Future<void> maybeShowInterstitialAfterExport() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_exportCounterKey) ?? 0) + 1;

    if (count >= _exportsPerInterstitial) {
      await prefs.setInt(_exportCounterKey, 0);
      await _loadAndShowInterstitial();
    } else {
      await prefs.setInt(_exportCounterKey, count);
    }
  }

  Future<void> _loadAndShowInterstitial() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }
}
