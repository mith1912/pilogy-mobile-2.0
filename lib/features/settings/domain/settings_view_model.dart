import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/storage/preferences_provider.dart';

/// Preference only: no scheduler or system notification permission request.
class SettingsViewModel extends AsyncNotifier<bool> {
  static const reminderKey = 'pilogy.v1.reminder_preference';
  @override
  Future<bool> build() async =>
      (await ref.watch(preferencesProvider.future)).getBool(reminderKey) ??
      false;
  Future<void> setReminder(bool value) async {
    if (state.isLoading) return;
    final previous = state;
    state = const AsyncLoading<bool>().copyWithPrevious(previous);
    try {
      final preferences = await ref.read(preferencesProvider.future);
      if (!await preferences.setBool(reminderKey, value))
        throw const FormatException('preference_write_failed');
      state = AsyncData(value);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, bool>(SettingsViewModel.new);
