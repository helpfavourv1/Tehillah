import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/core/ports/log_port.dart';

ConsentStatus consentStatusFrom(ads.ConsentStatus status) {
  switch (status) {
    case ads.ConsentStatus.notRequired:
      return ConsentStatus.notRequired;
    case ads.ConsentStatus.obtained:
      return ConsentStatus.obtained;
    case ads.ConsentStatus.required:
      return ConsentStatus.required;
    case ads.ConsentStatus.unknown:
      return ConsentStatus.unknown;
  }
}

/// Google's User Messaging Platform, the certified consent platform. It shows
/// the form in the EEA, the UK and Switzerland and nowhere else; the app only
/// asks it for the result.
///
/// To test a region before release, pass [debugGeography] (and the device's hashed
/// ID in [testDeviceIds]); both are for debug builds only.
final class ConsentService implements ConsentPort {
  ConsentService({
    this.debugGeography,
    this.testDeviceIds = const <String>[],
    LogPort? log,
  }) : _log = log;

  final ads.DebugGeography? debugGeography;
  final List<String> testDeviceIds;
  final LogPort? _log;

  static const Duration _updateTimeout = Duration(seconds: 20);
  static const Duration _formTimeout = Duration(minutes: 10);

  ads.ConsentRequestParameters get _parameters => ads.ConsentRequestParameters(
        consentDebugSettings: debugGeography == null
            ? null
            : ads.ConsentDebugSettings(
                debugGeography: debugGeography,
                testIdentifiers: testDeviceIds,
              ),
      );

  Future<ConsentSnapshot> _snapshot() async {
    final ads.ConsentInformation info = ads.ConsentInformation.instance;
    final ads.ConsentStatus status = await info.getConsentStatus();
    final bool canRequest = await info.canRequestAds();
    final ads.PrivacyOptionsRequirementStatus options = await info.getPrivacyOptionsRequirementStatus();
    return ConsentSnapshot(
      status: consentStatusFrom(status),
      canRequestAds: canRequest,
      privacyOptionsRequired: options == ads.PrivacyOptionsRequirementStatus.required,
    );
  }

  @override
  Future<ConsentSnapshot> current() => _snapshot();

  @override
  Future<ConsentSnapshot> refresh() async {
    final Completer<void> updated = Completer<void>();
    ads.ConsentInformation.instance.requestConsentInfoUpdate(
      _parameters,
      () => updated.complete(),
      (ads.FormError error) =>
          updated.completeError(StateError('consent update failed: ${error.message}')),
    );
    await updated.future.timeout(_updateTimeout);

    final Completer<ads.FormError?> shown = Completer<ads.FormError?>();
    await ads.ConsentForm.loadAndShowConsentFormIfRequired(shown.complete);
    final ads.FormError? formError = await shown.future.timeout(_formTimeout);
    if (formError != null) {
      _log?.log(LogLevel.warning, 'consent', 'consent form problem: ${formError.message}');
    }
    return _snapshot();
  }

  @override
  Future<ConsentSnapshot> showPrivacyOptions() async {
    final Completer<ads.FormError?> shown = Completer<ads.FormError?>();
    await ads.ConsentForm.showPrivacyOptionsForm(shown.complete);
    final ads.FormError? formError = await shown.future.timeout(_formTimeout);
    if (formError != null) {
      _log?.log(LogLevel.warning, 'consent', 'privacy options problem: ${formError.message}');
    }
    return _snapshot();
  }
}
