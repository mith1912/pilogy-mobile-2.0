import '../services/notifications/push_notifications.dart';
import '../services/ads/ad_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/app_theme.dart';
import 'router.dart';
import 'startup.dart';
import '../features/profiles/presentation/profiles_view_model.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../services/storage/preferences_provider.dart';

class PilogyApp extends ConsumerWidget {
  const PilogyApp({super.key, this.useGoogleFonts = true});

  /// Tests use system fonts so they never depend on font downloads.
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider);
    if (!startup.hasValue) {
      return MaterialApp(
        title: 'PILOGY',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
        home: SplashScreen(
          error: startup.hasError ? 'Không thể mở dữ liệu trên thiết bị.' : null,
          onRetry: () {
            ref.invalidate(preferencesProvider);
            ref.invalidate(startupProvider);
          },
        ),
      );
    }
    ref.watch(profilesViewModelProvider);
    return MaterialApp.router(
      title: 'PILOGY',
      scaffoldMessengerKey: pushMessengerKey,
      restorationScopeId: 'pilogy-app',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
      routerConfig: ref.watch(routerProvider),
      builder:
          (context, child) => AdRuntime(
            returningUser: startup.value!.selectedProfile != null,
            child: child ?? const SizedBox.shrink(),
          ),
    );
  }
}
