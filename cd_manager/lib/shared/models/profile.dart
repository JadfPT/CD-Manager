class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isAdmin,
    required this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String? username;
  final String? displayName;
  final bool isAdmin;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      isAdmin: map['is_admin'] as bool? ?? false,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: _asDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'is_admin': isAdmin,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }
}
