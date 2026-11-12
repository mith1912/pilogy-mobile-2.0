import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profiles/data/local_profile_repository.dart';
import '../features/profiles/domain/profile_repository.dart';
import '../services/storage/preferences_provider.dart';

/// Local-only startup. API/Firebase availability never controls profile access.
final startupProvider = FutureProvider<ProfileSnapshot>((ref) async {
  await ref.watch(preferencesProvider.future);
  return ref.watch(profileRepositoryProvider).getSnapshot();
});
String initialProfileLocation(ProfileSnapshot snapshot) =>
    snapshot.selectedProfile != null
        ? '/discover'
        : snapshot.profiles.isNotEmpty
        ? '/profiles'
        : '/welcome';
