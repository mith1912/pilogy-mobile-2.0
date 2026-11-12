import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_data_exception.dart';
import '../../profiles/data/local_profile_repository.dart';
import '../../profiles/domain/profile_repository.dart';

abstract interface class ProfileExportDriver {
  Future<bool> export(String json);
}

class SystemProfileExport implements ProfileExportDriver {
  static const channel = MethodChannel('mt.numerology/export');
  @override
  Future<bool> export(String json) async {
    try {
      return await channel.invokeMethod<bool>('exportProfiles', {
            'json': json,
          }) ??
          false;
    } catch (_) {
      throw const LocalDataException(LocalDataFailure.unavailable);
    }
  }
}

class LocalDataActions {
  LocalDataActions(this.profiles, this.exporter);
  final ProfileRepository profiles;
  final ProfileExportDriver exporter;
  Future<bool> exportProfiles() async {
    final data = await profiles.getAllProfiles();
    return exporter.export(
      const JsonEncoder.withIndent('  ').convert({
        'format': 'pilogy-profiles',
        'version': 1,
        'profiles': [for (final profile in data) profile.toMap()],
      }),
    );
  }
}

final profileExportDriverProvider = Provider<ProfileExportDriver>(
  (ref) => SystemProfileExport(),
);
final localDataActionsProvider = Provider<LocalDataActions>(
  (ref) => LocalDataActions(
    ref.watch(profileRepositoryProvider),
    ref.watch(profileExportDriverProvider),
  ),
);
