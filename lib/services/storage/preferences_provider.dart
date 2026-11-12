import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

abstract final class PreferenceKeys {
  static const themeMode = 'theme_mode';
  static const locale = 'locale';
  static const onboardingComplete = 'onboarding_complete';
  static const notificationsEnabled = 'notifications_enabled';
}
