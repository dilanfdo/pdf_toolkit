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
  ///
  /// Every step is time-bounded. Found by testing on a real device: if the
  /// native consent-info request never calls back (bad network, a
  /// reachability issue reaching Google's consent servers, anything), the
  /// success/failure callback pair alone doesn't help — neither ever fires,
  /// so an un-timed-out await here hangs forever and the app never gets
  /// past its launch splash. That's a strictly worse failure mode than
  /// having no consent handling at all, so this must never be allowed to
  /// block startup indefinitely: on timeout, proceed with ads simply not
  /// requested this session (canRequestAdsSync stays false) rather than
  /// leave the user staring at a frozen splash screen.
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

    try {
      await _requestConsentInfoUpdate(params).timeout(const Duration(seconds: 10));
      await _loadAndShowFormIfRequired().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // Fall through — ads just won't be requested this session.
    }

    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Proceed regardless — worst case, individual ad requests fail later.
    }

    canRequestAdsSync = await ConsentInformation.instance
        .canRequestAds()
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
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
