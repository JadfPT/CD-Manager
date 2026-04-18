class UserFavoriteAlbum {
  const UserFavoriteAlbum({
    required this.userId,
    required this.albumId,
    required this.createdAt,
  });

  final String userId;
  final int albumId;
  final DateTime? createdAt;

  factory UserFavoriteAlbum.fromMap(Map<String, dynamic> map) {
    return UserFavoriteAlbum(
      userId: map['user_id'] as String,
      albumId: _asInt(map['album_id']),
      createdAt: _asDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'album_id': albumId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }
}
