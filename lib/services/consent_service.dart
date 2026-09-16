import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Gathers ad-consent (GDPR/UK) via Google's User Messaging Platform before
/// any ad is requested. Required by both AdMob policy and EU/UK law for
/// users in those regions — UMP determines locally whether a given user
/// actually needs to see a form; everyone else sails through untouched.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// Cached synchronously after [gatherConsentAndInitializeAds] resolves, so
  /// ad-serving code (BannerAd/InterstitialAd creation, both currently
  /// synchronous call sites) can check it without awaiting a platform call
  /// on every ad request.
  bool canRequestAdsSync = false;

  /// Runs the consent flow (showing a form only if UMP decides the user's
  /// region requires one), then initializes the Mobile Ads SDK and caches
  /// whether ads may be requested into [canRequestAdsSync].
  Future<void> gatherConsentAndInitializeAds() async {
    final params = ConsentRequestParameters(
      consentDebugSettings: kReleaseMode
          ? null
          // Debug-only: simulate an EEA user so the consent form can
          // actually be exercised during development. Google requires
          // listing the test device's advertising ID here; logcat prints
          // the exact ID to add on first run ("Use new
          // ConsentDebugSettings.Builder().addTestDeviceHashedId(...)").
          : ConsentDebugSettings(debugGeography: DebugGeography.debugGeographyEea),
    );

    await _requestConsentInfoUpdate(params);
    await _loadAndShowFormIfRequired();
    await MobileAds.instance.initialize();
    canRequestAdsSync = await ConsentInformation.instance.canRequestAds();
  }

  Future<PrivacyOptionsRequirementStatus> get privacyOptionsRequirement =>
      ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

  /// Lets a user revisit their consent choice later (e.g. from Settings) —
  /// Google requires apps to offer this, not just show the form once.
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) => completer.complete());
    await completer.future;
    canRequestAdsSync = await ConsentInformation.instance.canRequestAds();
  }

  Future<void> _requestConsentInfoUpdate(ConsentRequestParameters params) {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => completer.complete(),
      // Fail open: if the consent info fetch itself fails (e.g. no network
      // on first launch), don't block the whole app on it. canRequestAds()
      // will correctly report false until a future successful update.
      (error) => completer.complete(),
    );
    return completer.future;
  }

  Future<void> _loadAndShowFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((formError) => completer.complete());
    return completer.future;
  }
}
