import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/ads/ad_analytics.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';

void main() {
  test(
    'Analytics deny gate avoids Firebase calls and restricts event names',
    () {
      final analytics = FirebaseAdAnalytics(canLog: () => false, testing: true);
      for (final event in FirebaseAdAnalytics.events) {
        expect(() => analytics.event(event, AdFormat.banner), returnsNormally);
      }
      expect(
        () => analytics.event('raw_payload', AdFormat.banner),
        returnsNormally,
      );
      expect(FirebaseAdAnalytics.events.length, 6);
    },
  );
}
