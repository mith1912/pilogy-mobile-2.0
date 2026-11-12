import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/app_theme.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../services/ads/ad_configuration.dart';
import '../services/ads/ad_providers.dart';
import '../services/firebase/firebase_bootstrap.dart';
import '../services/notifications/push_notifications.dart';
import 'app.dart';

class LaunchServices {
  const LaunchServices(this.ads, this.firebase);
  final AdConfiguration ads;
  final FirebaseStartupStatus firebase;
}

/// Render the splash before optional service initialization can delay startup.
final launchServicesProvider = FutureProvider<LaunchServices>((ref) async {
  final ads = await AdConfiguration.load();
  final firebase = await FirebaseStartup.initialize();
  return LaunchServices(ads, firebase);
});

class PilogyLaunch extends ConsumerStatefulWidget {
  const PilogyLaunch({super.key, this.useGoogleFonts = true});
  final bool useGoogleFonts;
  @override
  ConsumerState<PilogyLaunch> createState() => _PilogyLaunchState();
}

class _PilogyLaunchState extends ConsumerState<PilogyLaunch> {
  bool _notificationsScheduled = false;
  @override
  Widget build(BuildContext context) {
    final services = ref.watch(launchServicesProvider);
    final ready = services.valueOrNull;
    if (ready == null) {
      return MaterialApp(
        title: 'PILOGY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(useGoogleFonts: widget.useGoogleFonts),
        home: SplashScreen(
          error: services.hasError ? 'Không thể mở ứng dụng. Vui lòng thử lại.' : null,
          onRetry: () => ref.invalidate(launchServicesProvider),
        ),
      );
    }
    if (!_notificationsScheduled) {
      _notificationsScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(PushNotifications.initialize(ready.firebase));
      });
    }
    return ProviderScope(
      overrides: [
        adConfigurationProvider.overrideWithValue(ready.ads),
        firebaseStartupStatusProvider.overrideWithValue(ready.firebase),
      ],
      child: PilogyApp(useGoogleFonts: widget.useGoogleFonts),
    );
  }
}
