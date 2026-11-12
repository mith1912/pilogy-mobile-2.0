import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_diagnostics.dart';
import 'ad_mob_service.dart';

/// Manual debug-only entry. SDK additionally requires a registered test device.
Future<void> openDebugAdInspector(AdMobService service) async {
  if (!kDebugMode || !service.config.testing || !service.canRequest ||
      service.dialogOpen || service.policy.presenting) {
    AdDiagnostics.stage('inspector_skipped');
    return;
  }
  service.context(screen: service.screen,
      calculationBusy: service.calculationBusy, dialogOpen: true);
  void closed() => service.context(screen: service.screen,
      calculationBusy: service.calculationBusy, dialogOpen: false);
  try {
    MobileAds.instance.openAdInspector((error) {
      AdDiagnostics.stage(error == null ? 'inspector_closed' : 'inspector_failed',
          code: error?.code);
      closed();
    });
  } catch (_) {
    AdDiagnostics.stage('inspector_unavailable');
    closed();
  }
}
