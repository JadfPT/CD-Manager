import 'item_type.dart';

enum WishlistStatus {
  pending,
  approved,
  converted,
  rejected,
}

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.idColumn,
    required this.userId,
    required this.title,
    required this.itemType,
    required this.status,
    required this.createdAt,
    this.artistId,
    this.artistName,
    this.formatEdition,
    this.notes,
    this.requesterDisplayName,
    this.requesterUsername,
  });

  final int id;
  final String idColumn;
  final String userId;
  final String title;
  final int? artistId;
  final String? artistName;
  final ItemType itemType;
  final String? formatEdition;
  final String? notes;
  final WishlistStatus status;
  final DateTime? createdAt;
  final String? requesterDisplayName;
  final String? requesterUsername;

  String get displayArtistName {
    final fallback = artistName?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return 'Artista não definido';
  }

  String get dbItemType => itemType == ItemType.cd ? 'cd' : 'vinyl';

  String get dbStatus => status.name;

  String get requesterLabel {
    final display = requesterDisplayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final username = requesterUsername?.trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return userId;
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: _asInt(map['id']),
      idColumn: (map['id_column'] as String?) ?? 'id',
      userId: map['user_id'] as String,
      title: map['title'] as String,
      artistId: map['artist_id'] == null ? null : _asInt(map['artist_id']),
      artistName: map['artist_name'] as String?,
      itemType: _itemTypeFromDb(map['item_type'] as String?),
      formatEdition: map['format_edition'] as String?,
      notes: map['notes'] as String?,
      status: _statusFromDb(map['status'] as String?),
      createdAt: _asDateTime(map['created_at']),
      requesterDisplayName: map['requester_display_name'] as String?,
      requesterUsername: map['requester_username'] as String?,
    );
  }

  static ItemType _itemTypeFromDb(String? value) {
    final normalized = (value ?? 'cd').toLowerCase();
    return normalized == 'vinyl' ? ItemType.vinyl : ItemType.cd;
  }

  static WishlistStatus _statusFromDb(String? value) {
    final normalized = (value ?? 'pending').toLowerCase();
    return switch (normalized) {
      'approved' => WishlistStatus.approved,
      'converted' => WishlistStatus.converted,
      'rejected' => WishlistStatus.rejected,
      _ => WishlistStatus.pending,
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
