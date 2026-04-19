class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.genreText,
    required this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? genreText;
  final String? imageUrl;
  final DateTime? createdAt;

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: _asInt(map['id']),
      name: map['name'] as String,
      genreText: map['genre_text'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt: _asDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genre_text': genreText,
      'image_url': imageUrl,
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
