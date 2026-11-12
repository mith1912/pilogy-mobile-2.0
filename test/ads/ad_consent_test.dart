import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/ads/ad_consent_service.dart';
import 'ad_test_support.dart';

void main() {
  test('one update/form despite concurrent initialization', () async {
    final native = FakeConsent()..wait = Completer<void>();
    final service = AdConsentService(native);
    final first = service.initialize(), second = service.initialize();
    expect(service.busy, isTrue);
    expect(service.allowed, isFalse);
    native.wait!.complete();
    await Future.wait([first, second]);
    expect(native.updates, 1);
    expect(native.forms, 1);
    expect(service.allowed, isTrue);
    service.dispose();
  });
  test('unavailable or denied UMP never grants ads', () async {
    for (final fail in [true, false]) {
      final service = AdConsentService(
        FakeConsent()
          ..fail = fail
          ..allowed = false,
      );
      await service.initialize();
      expect(service.allowed, isFalse);
      expect(service.busy, isFalse);
      service.dispose();
    }
  });
  test(
    'privacy options are exposed according to UMP and re-check eligibility',
    () async {
      final native = FakeConsent()..required = true;
      final service = AdConsentService(native);
      await service.initialize();
      expect(service.privacyRequired, isTrue);
      native.allowed = false;
      await service.privacyOptions();
      expect(native.privacyForms, 1);
      expect(service.allowed, isFalse);
      service.dispose();
    },
  );
}
