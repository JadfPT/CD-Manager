import 'item_type.dart';

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.onShelf,
    required this.coverUrl,
    required this.createdAt,
    this.formatEdition,
  });

  final int id;
  final String title;
  final int artistId;
  final bool onShelf;
  final String? coverUrl;
  final DateTime? createdAt;
  final String? formatEdition;

  // Implicitly CD type since cd_albums only contains CDs
  ItemType get itemType => ItemType.cd;

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: _asInt(map['id']),
      title: map['title'] as String,
      artistId: _asInt(map['artist_id']),
      onShelf: map['on_shelf'] as bool,
      coverUrl: map['cover_url'] as String?,
      createdAt: _asDateTime(map['created_at']),
      formatEdition: map['format_edition'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'on_shelf': onShelf,
      'cover_url': coverUrl,
      'format_edition': formatEdition,
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

