import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_data_exception.dart';
import '../data/local_profile_repository.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

// Retain the M01 import surface for provider overrides.
export '../data/local_profile_repository.dart' show profileRepositoryProvider;

typedef ProfilesState = ProfileSnapshot;

class ProfilesViewModel extends AutoDisposeAsyncNotifier<ProfilesState> {
  Future<void> _pending = Future<void>.value();

  @override
  Future<ProfilesState> build() =>
      ref.watch(profileRepositoryProvider).getSnapshot();

  /// Serialize writes and refresh atomically from the same repository snapshot.
  /// Existing data stays visible during writes; forms own their busy/error state.
  Future<T> _write<T>(Future<T> Function(ProfileRepository) operation) {
    final repository = ref.read(profileRepositoryProvider);
    final keepAlive = ref.keepAlive();
    final result = _pending.then((_) async {
      try {
        if (state.isLoading) await future;
        final value = await operation(repository);
        state = AsyncData(await repository.getSnapshot());
        return value;
      } finally {
        keepAlive.close();
      }
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<UserProfile> createProfile({
    required String fullName,
    required String birthDate,
  }) => _write(
    (repository) =>
        repository.createProfile(fullName: fullName, birthDate: birthDate),
  );

  Future<UserProfile> updateProfile({
    required String id,
    required String fullName,
    required String birthDate,
  }) => _write(
    (repository) => repository.updateProfile(
      id: id,
      fullName: fullName,
      birthDate: birthDate,
    ),
  );

  Future<void> deleteProfile(String id) =>
      _write((repository) => repository.deleteProfile(id));
  Future<void> deleteAllProfiles() =>
      _write((repository) => repository.deleteAllProfiles());
  Future<void> selectProfile(String? id) =>
      _write((repository) => repository.selectProfile(id));

  Future<UserProfile> saveAndSelect({
    String? id,
    required String fullName,
    required String birthDate,
  }) => _write((repository) async {
    final saved =
        id == null
            ? await repository.createProfile(
              fullName: fullName,
              birthDate: birthDate,
            )
            : await repository.updateProfile(
              id: id,
              fullName: fullName,
              birthDate: birthDate,
            );
    await repository.selectProfile(saved.id);
    return saved;
  });

  Future<void> refresh() => _write((repository) async {});
}

final profilesViewModelProvider =
    AsyncNotifierProvider.autoDispose<ProfilesViewModel, ProfilesState>(
      ProfilesViewModel.new,
    );

final selectedProfileProvider = Provider.autoDispose<AsyncValue<UserProfile?>>(
  (ref) => ref
      .watch(profilesViewModelProvider)
      .whenData((snapshot) => snapshot.selectedProfile),
);

String localDataErrorMessage(Object error) {
  if (error is LocalDataException &&
      error.failure == LocalDataFailure.notFound) {
    return 'Hồ sơ không còn trên thiết bị. Vui lòng tải lại danh sách.';
  }
  if (error is LocalDataException &&
      error.failure == LocalDataFailure.invalidInput) {
    return 'Vui lòng kiểm tra họ tên và ngày sinh.';
  }
  return 'Không thể truy cập dữ liệu trên thiết bị. Vui lòng thử lại.';
}
