import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/firebase/firebase_bootstrap.dart';
import 'package:pilogy_app/services/firebase/firebase_configuration.dart';

class FakeFirebaseDriver implements FirebaseDriver {
  FakeFirebaseDriver(this.identity);
  final FirebaseIdentity identity;
  int starts = 0;
  final collections = <bool>[];
  bool fail = false;
  @override
  Future<FirebaseIdentity> initializeCore() async {
    starts++;
    if (fail) throw StateError('test-only initialization error');
    return identity;
  }

  @override
  Future<void> configureTelemetry(bool enabled) async {
    collections.add(enabled);
  }

  @override
  Future<void> recordFrameworkFailure() async {}
  @override
  Future<void> recordUnhandledFailure() async {}
}

void main() {
  test(
    'matching Android identity initializes SDKs with telemetry disabled by default',
    () async {
      final driver = FakeFirebaseDriver(
        const FirebaseIdentity(
          FirebaseConfiguration.projectId,
          FirebaseConfiguration.androidAppId,
        ),
      );
      expect(
        await FirebaseStartup.initialize(
          driver: driver,
          platform: TargetPlatform.android,
          enableTelemetry: false,
          installErrorHandlers: false,
        ),
        FirebaseStartupStatus.ready,
      );
      expect(driver.collections, [false]);
    },
  );
  test('matching iOS identity can explicitly enable telemetry', () async {
    final driver = FakeFirebaseDriver(
      const FirebaseIdentity(
        FirebaseConfiguration.projectId,
        FirebaseConfiguration.iosAppId,
      ),
    );
    expect(
      await FirebaseStartup.initialize(
        driver: driver,
        platform: TargetPlatform.iOS,
        enableTelemetry: true,
        installErrorHandlers: false,
      ),
      FirebaseStartupStatus.ready,
    );
    expect(driver.collections, [true]);
  });
  test('mismatched identity stops analytics and crash integration', () async {
    final driver = FakeFirebaseDriver(
      const FirebaseIdentity('wrong-project', 'wrong-app'),
    );
    expect(
      await FirebaseStartup.initialize(
        driver: driver,
        platform: TargetPlatform.android,
        enableTelemetry: true,
        installErrorHandlers: false,
      ),
      FirebaseStartupStatus.invalidConfiguration,
    );
    expect(driver.collections, isEmpty);
  });
  test('unsupported platform makes no Firebase calls', () async {
    final driver = FakeFirebaseDriver(const FirebaseIdentity('', ''));
    expect(
      await FirebaseStartup.initialize(
        driver: driver,
        platform: TargetPlatform.linux,
        installErrorHandlers: false,
      ),
      FirebaseStartupStatus.unsupportedPlatform,
    );
    expect(driver.starts, 0);
  });
  test('startup failure does not prevent local-only app startup', () async {
    final driver = FakeFirebaseDriver(const FirebaseIdentity('', ''))
      ..fail = true;
    expect(
      await FirebaseStartup.initialize(
        driver: driver,
        platform: TargetPlatform.android,
        installErrorHandlers: false,
      ),
      FirebaseStartupStatus.unavailable,
    );
    expect(driver.collections, isEmpty);
  });
}
