enum LocalDataFailure {
  unavailable,
  notFound,
  invalidInput,
  unsupportedSchema,
  closed,
}

/// Safe codes only. Never retain SQL, submitted fields or platform exception text.
class LocalDataException implements Exception {
  const LocalDataException(this.failure, {this.field});
  final LocalDataFailure failure;
  final String? field;
}

Future<T> protectLocalData<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on LocalDataException {
    rethrow;
  } catch (_) {
    throw const LocalDataException(LocalDataFailure.unavailable);
  }
}
