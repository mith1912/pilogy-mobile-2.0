import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/presentation/pilogy_scaffold.dart';
import 'package:pilogy_app/services/ads/ad_consent_service.dart';
import 'package:pilogy_app/services/ads/ad_mob_service.dart';
import 'package:pilogy_app/services/ads/ad_providers.dart';
import 'ad_test_support.dart';

void main() {
  testWidgets('banner stays above navigation when content scrolls and hides for keyboard', (tester) async {
    final consent = AdConsentService(FakeConsent());
    final sdk = FakeAds();
    final service = AdMobService(
      config: configuration(), consent: consent, gateway: sdk,
    );
    service.context(screen: 'discover', calculationBusy: false, dialogOpen: false);
    await service.start(returning: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [adMobServiceProvider.overrideWith((ref) => service)],
      child: MaterialApp(home: PilogyScaffold(
        screenId: 'V03', title: 'PILOGY', tab: 0,
        children: List.generate(30, (index) => SizedBox(
          height: 80, child: Text('Item $index'),
        )),
      )),
    ));
    await tester.pumpAndSettle();
    final banner = find.byKey(const ValueKey('test-banner-view'));
    expect(banner, findsOneWidget);
    final position = tester.getTopLeft(banner);
    expect(tester.getBottomLeft(banner).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(banner), position);
    expect(sdk.bannerLoads, 1);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(banner, findsOneWidget);
    expect(sdk.bannerLoads, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    consent.dispose();
  });
}
