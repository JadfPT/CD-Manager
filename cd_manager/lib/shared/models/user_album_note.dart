class UserAlbumNote {
  const UserAlbumNote({
    required this.userId,
    required this.albumId,
    required this.note,
    required this.updatedAt,
  });

  final String userId;
  final int albumId;
  final String note;
  final DateTime? updatedAt;

  factory UserAlbumNote.fromMap(Map<String, dynamic> map) {
    return UserAlbumNote(
      userId: map['user_id'] as String,
      albumId: _asInt(map['album_id']),
      note: map['note'] as String,
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'album_id': albumId,
      'note': note,
      'updated_at': updatedAt?.toIso8601String(),
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
