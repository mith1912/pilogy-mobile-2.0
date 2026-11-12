import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'ad_configuration.dart';
import 'ad_gateway.dart';

/// Injectable bridge. Caller must supply an independently verified Analytics
/// consent gate; UMP canRequestAds is not Analytics consent. Off by default.
class FirebaseAdAnalytics implements AdAnalyticsService {
  FirebaseAdAnalytics({required this.canLog, required this.testing});
  final bool Function() canLog;
  final bool testing;
  static const events = {
    'ad_load_requested',
    'ad_loaded',
    'ad_load_failed',
    'ad_displayed',
    'ad_closed',
    'ad_display_failed',
  };
  @override
  void event(String name, AdFormat format) {
    if (!events.contains(name) || !canLog()) return;
    unawaited(
      FirebaseAnalytics.instance
          .logEvent(
            name: name,
            parameters: {
              'ad_format': format.name,
              'ad_mode': testing ? 'test' : 'production',
            },
          )
          .catchError((Object _) {}),
    );
  }
}
