import '../services/ads/ad_providers.dart';
import '../services/ads/ad_navigation_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/widgets/app_components.dart';
import '../features/numerology/domain/api_models.dart';
import 'startup.dart';
import '../features/welcome/presentation/welcome_screen.dart';
import '../features/profiles/presentation/profile_form_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/analysis/presentation/analysis_screen.dart';
import '../features/number_detail/presentation/number_detail_screen.dart';
import '../features/profiles/presentation/profiles_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/privacy_data/presentation/privacy_data_screen.dart';

GoRouter createRouter({
  String initialLocation = '/welcome',
  List<NavigatorObserver> observers = const [],
}) => GoRouter(
  initialLocation: initialLocation,
  observers: observers,
  restorationScopeId: 'pilogy-router',
  routes: [
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/profile-form',
      name: 'profileForm',
      builder:
          (context, state) =>
              ProfileFormScreen(profileId: state.uri.queryParameters['edit']),
    ),
    GoRoute(
      path: '/discover',
      name: 'discover',
      builder: (context, state) => const DiscoverScreen(),
    ),
    GoRoute(
      path: '/analysis',
      name: 'analysis',
      builder: (context, state) => const AnalysisScreen(),
    ),
    GoRoute(
      path: '/number-detail',
      name: 'numberDetail',
      builder:
          (context, state) => NumberDetailScreen(
            type: parseDetailType(state.uri.queryParameters['type']),
          ),
    ),
    GoRoute(
      path: '/profiles',
      name: 'profiles',
      builder: (context, state) => const ProfilesScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/privacy-data',
      name: 'privacyData',
      builder: (context, state) => const PrivacyDataScreen(),
    ),
  ],
  errorBuilder:
      (context, state) => const Scaffold(
        body: SafeArea(
          child: Center(child: AppEmptyState(message: 'Không tìm thấy trang.')),
        ),
      ),
);

final routerProvider = Provider<GoRouter>((ref) {
  final snapshot = ref.read(startupProvider).valueOrNull;
  final router = createRouter(
    initialLocation:
        snapshot == null ? '/welcome' : initialProfileLocation(snapshot),
    observers: [AdNavigationObserver(ref.read(adMobServiceProvider))],
  );
  ref.onDispose(router.dispose);
  return router;
}, dependencies: [startupProvider, adMobServiceProvider]);

IndexType? parseDetailType(String? value) {
  for (final type in IndexType.values) {
    if (type.name == value) return type;
  }
  return null;
}
