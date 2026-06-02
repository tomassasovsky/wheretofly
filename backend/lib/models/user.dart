import 'package:postgres/postgres.dart';

/// Authenticated user profile returned by the API.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.handle,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.emailVerified,
    required this.followMode,
    required this.createdAt,
  });

  factory UserProfile.fromRow(ResultRow row) {
    return UserProfile(
      id: row[0]! as String,
      email: row[1]! as String,
      handle: row[2]! as String,
      displayName: row[3]! as String,
      bio: row[4]! as String,
      avatarUrl: row[5] as String?,
      emailVerified: row[6] != null,
      followMode: row[7]! as String,
      createdAt: (row[8] as DateTime?) ?? DateTime.now(),
    );
  }

  final String id;
  final String email;
  final String handle;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final bool emailVerified;
  final String followMode;
  final DateTime createdAt;

  Map<String, dynamic> toPublicJson({bool includeEmail = false}) {
    return {
      'id': id,
      'handle': handle,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'emailVerified': emailVerified,
      'followMode': followMode,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (includeEmail) 'email': email,
    };
  }
}
