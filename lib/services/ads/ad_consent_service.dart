import 'package:flutter/foundation.dart';
import 'ad_diagnostics.dart';

abstract interface class ConsentGateway {
  Future<void> update();
  Future<void> showRequiredForm();
  Future<bool> canRequestAds();
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();
}

/// UMP owns consent storage. No location guesses or fabricated local consent.
class AdConsentService extends ChangeNotifier {
  AdConsentService(this.gateway);
  final ConsentGateway gateway;
  Future<void>? _initialization;
  bool busy = false,
      allowed = false,
      privacyRequired = false,
      unavailable = false;
  bool _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() => _initialization ??= _run(false);
  Future<void> privacyOptions() async {
    if (busy || !privacyRequired || _disposed) return;
    await _run(true);
  }

  Future<void> _run(bool privacy) async {
    AdDiagnostics.stage(privacy ? 'privacy_options_started' : 'consent_started');
    busy = true;
    allowed = false;
    unavailable = false;
    _changed();
    try {
      if (privacy) {
        await gateway.showPrivacyOptions();
      } else {
        await gateway.update().timeout(const Duration(seconds: 15));
        if (_disposed) return;
        // Do not time out a visible native form and unlock fullscreen ads
        // underneath it. The app's core routes never await this future.
        await gateway.showRequiredForm();
      }
      final canRequest = await gateway.canRequestAds().timeout(
        const Duration(seconds: 10),
      );
      final required = await gateway.privacyOptionsRequired().timeout(
        const Duration(seconds: 10),
      );
      if (_disposed) return;
      allowed = canRequest;
      AdDiagnostics.stage(canRequest ? 'consent_allowed' : 'consent_not_eligible');
      privacyRequired = required;
    } catch (_) {
      allowed = false;
      unavailable = true;
      AdDiagnostics.stage('consent_unavailable');
      // Keep the privacy entry accessible after update/form errors if UMP knows
      // it is required. No ad eligibility is inferred from this query.
      try {
        privacyRequired = await gateway.privacyOptionsRequired().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {}
    } finally {
      busy = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
