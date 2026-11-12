import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';
import 'package:pilogy_app/services/ads/ad_frequency_policy.dart';
import 'ad_test_support.dart';

void main() {
  test('third unique completed visit, startup grace and shared cooldown', () {
    var now = DateTime(2026);
    final policy = AdFrequencyPolicy(configuration(), now: () => now);
    expect(policy.completeInterpretation(1), isTrue);
    expect(policy.completeInterpretation(1), isFalse);
    policy.completeInterpretation(2);
    policy.completeInterpretation(3);
    expect(policy.actions, 3);
    expect(policy.interstitialDue, isFalse);
    now = now.add(const Duration(seconds: 120));
    expect(policy.interstitialDue, isTrue);
    expect(policy.acquire(), isTrue);
    expect(policy.acquire(), isFalse);
    policy.shown(AdFormat.interstitial);
    expect(policy.actions, 0);
    policy.ended();
    expect(policy.canPresent, isFalse);
    expect(policy.appOpenDue(const Duration(minutes: 10)), isFalse);
    now = now.add(const Duration(seconds: 120));
    expect(policy.appOpenDue(const Duration(minutes: 4)), isFalse);
    expect(policy.appOpenDue(const Duration(minutes: 5)), isTrue);
    policy.foreground = false;
    expect(policy.canPresent, isFalse);
  });
  test('failed display does not consume completed action threshold', () {
    var now = DateTime(2026);
    final policy = AdFrequencyPolicy(configuration(), now: () => now);
    for (var i = 0; i < 3; i++) {
      policy.completeInterpretation(i);
    }
    now = now.add(const Duration(minutes: 3));
    policy.acquire();
    policy.ended();
    expect(policy.actions, 3);
    expect(policy.canPresent, isFalse);
  });
  test('combined session cap counts shown ads across formats only', () {
    var now = DateTime(2026);
    final policy = AdFrequencyPolicy(
      configuration(fullscreenSessionCap: 2), now: () => now,
    );
    now = now.add(const Duration(minutes: 3));
    expect(policy.acquire(), isTrue);
    policy.ended(); // Failed display does not consume the cap.
    expect(policy.fullscreenShown, 0);
    for (final format in [AdFormat.appOpen, AdFormat.interstitial]) {
      now = now.add(const Duration(minutes: 3));
      expect(policy.acquire(), isTrue);
      policy.shown(format);
      policy.ended();
    }
    now = now.add(const Duration(hours: 1));
    expect(policy.fullscreenLimitReached, isTrue);
    expect(policy.canPresent, isFalse);
    expect(policy.appOpenDue(const Duration(minutes: 10)), isFalse);
    final disabled = AdFrequencyPolicy(configuration(fullscreenSessionCap: 0));
    expect(disabled.fullscreenLimitReached, isTrue);
  });
  test('configured background interval still honors shared startup grace', () {
    var now = DateTime(2026);
    final policy = AdFrequencyPolicy(
      configuration(backgroundMinimum: const Duration(minutes: 2)), now: () => now,
    );
    expect(policy.appOpenDue(const Duration(minutes: 2)), isFalse);
    now = now.add(const Duration(minutes: 2));
    expect(policy.appOpenDue(const Duration(seconds: 119)), isFalse);
    expect(policy.appOpenDue(const Duration(minutes: 2)), isTrue);
  });

}
