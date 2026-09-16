import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'consent_service.dart';

/// Centralizes AdMob unit IDs and interstitial frequency capping.
///
/// Real ad unit IDs only get served in release builds. Debug/profile builds
/// always use Google's test ad units — serving real ones during development
/// generates impressions/clicks from the same device repeatedly, which
/// AdMob's invalid-traffic detection can flag and get the account suspended.
/// There is no real iOS app registered in AdMob yet, so iOS stays on test
/// IDs in every build mode until that's set up.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _exportCounterKey = 'export_count_since_last_ad';
  static const _exportsPerInterstitial = 3;

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIOS = 'ca-app-pub-3940256099942544/4411468910';

  static const _prodBannerAndroid = 'ca-app-pub-4607423166762045/8466652066';
  static const _prodInterstitialAndroid = 'ca-app-pub-4607423166762045/8833036469';

  String get bannerAdUnitId {
    if (Platform.isIOS || !kReleaseMode) {
      return Platform.isIOS ? _testBannerIOS : _testBannerAndroid;
    }
    return _prodBannerAndroid;
  }

  String get interstitialAdUnitId {
    if (Platform.isIOS || !kReleaseMode) {
      return Platform.isIOS ? _testInterstitialIOS : _testInterstitialAndroid;
    }
    return _prodInterstitialAndroid;
  }

  /// Returns null without creating anything if consent hasn't been
  /// obtained yet (required before requesting any ad — see ConsentService).
  BannerAd? createBannerAd({required void Function(Ad ad) onLoaded}) {
    if (!ConsentService.instance.canRequestAdsSync) return null;
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
    if (!ConsentService.instance.canRequestAdsSync) return;
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
