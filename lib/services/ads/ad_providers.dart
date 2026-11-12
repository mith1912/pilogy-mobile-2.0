import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_bootstrap.dart';
import 'ad_analytics.dart';
import 'ad_configuration.dart';
import 'ad_consent_service.dart';
import 'ad_gateway.dart';
import 'ad_mob_service.dart';
import 'google_ads_gateway.dart';

// Launch overrides configuration/Firebase in a child ProviderScope. Declare
// scoped dependencies through Analytics and the service so both resolve there.
final adConfigurationProvider = Provider<AdConfiguration>(
  (ref) => AdConfiguration.environment(),
  dependencies: const [],
);
final adGatewayProvider = Provider<AdGateway>(
  (ref) => GoogleAdsGateway(),
  dependencies: const [],
);
final consentGatewayProvider = Provider<ConsentGateway>(
  (ref) => GoogleConsentGateway(),
  dependencies: const [],
);
final adConsentProvider = ChangeNotifierProvider<AdConsentService>(
  (ref) => AdConsentService(ref.watch(consentGatewayProvider)),
  dependencies: [consentGatewayProvider],
);
// No consent UI for optional Analytics exists yet: keep this false. A future
// consent implementation may inject a verified value; never derive it from UMP.
final adAnalyticsConsentProvider = Provider<bool>(
  (ref) => false,
  dependencies: const [],
);
final adAnalyticsProvider = Provider<AdAnalyticsService>(
  (ref) => FirebaseAdAnalytics(
    testing: ref.watch(adConfigurationProvider).testing,
    canLog:
        () =>
            const bool.fromEnvironment('ENABLE_TELEMETRY') &&
            ref.read(firebaseStartupStatusProvider) ==
                FirebaseStartupStatus.ready &&
            ref.read(adAnalyticsConsentProvider) &&
            ref.read(adConsentProvider).allowed &&
            !ref.read(adConsentProvider).busy,
  ),
  dependencies: [
    adConfigurationProvider,
    firebaseStartupStatusProvider,
    adAnalyticsConsentProvider,
    adConsentProvider,
  ],
);
final adMobServiceProvider = ChangeNotifierProvider<AdMobService>(
  (ref) => AdMobService(
    config: ref.watch(adConfigurationProvider),
    consent: ref.read(adConsentProvider),
    gateway: ref.watch(adGatewayProvider),
    analytics: ref.watch(adAnalyticsProvider),
  ),
  dependencies: [
    adConfigurationProvider,
    adConsentProvider,
    adGatewayProvider,
    adAnalyticsProvider,
  ],
);
