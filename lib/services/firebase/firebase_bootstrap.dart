import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_configuration.dart';

enum FirebaseStartupStatus {
  ready,
  unsupportedPlatform,
  invalidConfiguration,
  unavailable,
}

class FirebaseIdentity {
  const FirebaseIdentity(this.projectId, this.appId);
  final String projectId;
  final String appId;
}

/// Small injectable seam: tests do not initialize Firebase or require credentials.
abstract interface class FirebaseDriver {
  Future<FirebaseIdentity> initializeCore();
  Future<void> configureTelemetry(bool enabled);
  Future<void> recordFrameworkFailure();
  Future<void> recordUnhandledFailure();
}

class NativeFirebaseDriver implements FirebaseDriver {
  @override
  Future<FirebaseIdentity> initializeCore() async {
    final app = await Firebase.initializeApp();
    return FirebaseIdentity(app.options.projectId, app.options.appId);
  }

  @override
  Future<void> configureTelemetry(bool enabled) async {
    final analytics = FirebaseAnalytics.instance;
    final crashlytics = FirebaseCrashlytics.instance;
    // Ad consent does not grant Analytics consent. Until a separate optional
    // Analytics choice is implemented, also prevent automatic AdMob events.
    await analytics.setAnalyticsCollectionEnabled(false);
    await analytics.setConsent(
      adStorageConsentGranted: false,
      analyticsStorageConsentGranted: false,
    );
    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
    // Clear any legacy user identity; never attach local profile identifiers.
    await analytics.setUserId(id: null);
    await crashlytics.setUserIdentifier('');
  }

  @override
  Future<void> recordFrameworkFailure() =>
      FirebaseCrashlytics.instance.recordError(
        'pilogy_framework_failure',
        StackTrace.current,
        reason: 'sanitized_framework_failure',
        printDetails: false,
        fatal: true,
      );

  @override
  Future<void> recordUnhandledFailure() =>
      FirebaseCrashlytics.instance.recordError(
        'pilogy_unhandled_failure',
        StackTrace.current,
        reason: 'sanitized_unhandled_failure',
        printDetails: false,
        fatal: true,
      );
}

class FirebaseStartup {
  static Future<FirebaseStartupStatus> initialize({
    FirebaseDriver? driver,
    TargetPlatform? platform,
    bool enableTelemetry = const bool.fromEnvironment('ENABLE_TELEMETRY'),
    bool installErrorHandlers = true,
  }) async {
    final target = platform ?? defaultTargetPlatform;
    if (kIsWeb ||
        (target != TargetPlatform.android && target != TargetPlatform.iOS)) {
      return FirebaseStartupStatus.unsupportedPlatform;
    }
    final native = driver ?? NativeFirebaseDriver();
    var validated = false;
    try {
      final identity = await native.initializeCore().timeout(
        const Duration(seconds: 5),
      );
      final expected =
          target == TargetPlatform.android
              ? FirebaseConfiguration.androidAppId
              : FirebaseConfiguration.iosAppId;
      if (identity.projectId != FirebaseConfiguration.projectId ||
          identity.appId != expected) {
        return FirebaseStartupStatus.invalidConfiguration;
      }
      validated = true;
      await native
          .configureTelemetry(enableTelemetry)
          .timeout(const Duration(seconds: 5));
      if (enableTelemetry && installErrorHandlers) {
        // Deliberately do not forward error objects, details, input values or
        // original stacks, any of which can contain profile/request information.
        FlutterError.onError = (details) {
          unawaited(native.recordFrameworkFailure().catchError((Object _) {}));
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(native.recordUnhandledFailure().catchError((Object _) {}));
          return true;
        };
      }
      return FirebaseStartupStatus.ready;
    } catch (_) {
      if (validated) {
        try {
          await native
              .configureTelemetry(false)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          /* Local app stays usable. */
        }
      }
      return FirebaseStartupStatus.unavailable;
    }
  }
}

final firebaseStartupStatusProvider = Provider<FirebaseStartupStatus>(
  (ref) => FirebaseStartupStatus.unsupportedPlatform,
  dependencies: const [],
);
