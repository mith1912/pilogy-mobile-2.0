import 'user_profile.dart';

class ProfileSnapshot {
  const ProfileSnapshot(this.profiles, this.selectedProfile);
  final List<UserProfile> profiles;
  final UserProfile? selectedProfile;
}

abstract interface class ProfileRepository {
  Future<UserProfile> createProfile({
    required String fullName,
    required String birthDate,
  });
  Future<UserProfile?> getProfileById(String id);
  Future<List<UserProfile>> getAllProfiles();
  Future<UserProfile> updateProfile({
    required String id,
    required String fullName,
    required String birthDate,
  });
  Future<void> deleteProfile(String id);
  Future<void> deleteAllProfiles();
  Future<void> selectProfile(String? id);
  Future<ProfileSnapshot> getSnapshot();
}
