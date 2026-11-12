import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/design_system/app_theme.dart';
import 'package:pilogy_app/core/design_system/widgets/app_components.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/user_profile.dart';
import 'package:pilogy_app/features/profiles/presentation/widgets/profile_input_form.dart';
import 'package:pilogy_app/features/profiles/presentation/widgets/profile_list.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<void> deleteAllProfiles() async {
    throw UnimplementedError();
  }

  final profiles = <UserProfile>[];
  String? selectedId;
  @override
  Future<UserProfile> createProfile({
    required String fullName,
    required String birthDate,
  }) async {
    final now = DateTime.utc(2026, 11, 9);
    final profile = UserProfile(
      id: 'fixture-${profiles.length}',
      fullName: fullName,
      birthDate: birthDate,
      createdAt: now,
      updatedAt: now,
    );
    profiles.add(profile);
    return profile;
  }

  @override
  Future<UserProfile?> getProfileById(String id) async {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async => List.of(profiles);
  @override
  Future<ProfileSnapshot> getSnapshot() async => ProfileSnapshot(
    List.of(profiles),
    selectedId == null ? null : await getProfileById(selectedId!),
  );
  @override
  Future<void> deleteProfile(String id) async {
    profiles.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> selectProfile(String? id) async {
    selectedId = id;
  }

  @override
  Future<UserProfile> updateProfile({
    required String id,
    required String fullName,
    required String birthDate,
  }) async => throw UnimplementedError('Unused UI fixture operation');
}

void main() {
  late FakeProfileRepository repository;
  setUp(() {
    repository = FakeProfileRepository();
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light(useGoogleFonts: false),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('form validates input then creates an offline Unicode profile', (
    tester,
  ) async {
    UserProfile? saved;
    await tester.pumpWidget(
      host(ProfileInputForm(onSaved: (profile) => saved = profile)),
    );
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập họ và tên khai sinh.'), findsOneWidget);
    final name = find.descendant(
      of: find.byKey(const ValueKey('profile-full-name')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(name, 'Đặng Thị Mỹ Duyên');
    await tester.enterText(
      find.byKey(const ValueKey('profile-date-Ngày')),
      '29',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-date-Tháng')),
      '02',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-date-Năm')),
      '2000',
    );
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(saved?.fullName, 'Đặng Thị Mỹ Duyên');
    expect(saved?.birthDate, '2000-02-29');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'edit form prepopulates profile and cancel deletion preserves it',
    (tester) async {
      final profile = await repository.createProfile(
        fullName: 'Nguyễn An',
        birthDate: '2000-02-29',
      );
      await tester.pumpWidget(host(ProfileInputForm(profile: profile)));
      expect(find.text('Nguyễn An'), findsOneWidget);
      expect(find.text('Cập nhật hồ sơ'), findsOneWidget);
      await tester.pumpWidget(
        host(
          Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    if (await confirmProfileDeletion(context))
                      await repository.deleteProfile(profile.id);
                  },
                  child: const Text('Delete test profile'),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Delete test profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy Bỏ'));
      await tester.pumpAndSettle();
      expect(await repository.getProfileById(profile.id), isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
