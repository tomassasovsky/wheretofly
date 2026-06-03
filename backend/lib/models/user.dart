import 'package:postgres/postgres.dart';

/// Authenticated user profile returned by the API.
class UserProfile {
  /// Creates a profile from explicit field values.
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

  /// Maps a `users` table row to a [UserProfile].
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

  /// Primary key UUID.
  final String id;

  /// Login email address.
  final String email;

  /// Unique @handle slug.
  final String handle;

  /// Display name shown in the UI.
  final String displayName;

  /// Profile biography text.
  final String bio;

  /// Avatar image URL, if set.
  final String? avatarUrl;

  /// Whether the user has verified their email.
  final bool emailVerified;

  /// Follow policy: `open` or `approval`.
  final String followMode;

  /// Account creation timestamp.
  final DateTime createdAt;

  /// JSON safe for public profile endpoints.
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
