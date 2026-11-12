/// Personal data remains local except transient backend calculation inputs (M03).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.birthDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;

  /// Gregorian YYYY-MM-DD, not a local or UTC timestamp.
  final String birthDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.fullName == fullName &&
      other.birthDate == birthDate &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  // Object equality only; never used as a cache input fingerprint or telemetry ID.
  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt);

  factory UserProfile.fromMap(Map<String, Object?> row) => UserProfile(
    id: row['id']! as String,
    fullName: row['full_name']! as String,
    birthDate: row['birth_date']! as String,
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'full_name': fullName,
    'birth_date': birthDate,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}
