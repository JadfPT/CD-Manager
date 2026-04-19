import 'item_type.dart';

class AlbumLoan {
  const AlbumLoan({
    required this.id,
    required this.albumId,
    required this.borrowedByUserId,
    required this.borrowedAt,
    required this.returnedAt,
    this.itemType = ItemType.cd,
  });

  final int id;
  final int albumId;
  final String borrowedByUserId;
  final DateTime borrowedAt;
  final DateTime? returnedAt;
  final ItemType itemType;

  bool get isActive => returnedAt == null;

  factory AlbumLoan.fromMap(Map<String, dynamic> map) {
    return AlbumLoan(
      id: _asInt(map['id']),
      albumId: _asInt(map['item_id']),
      borrowedByUserId: map['borrowed_by_user_id'] as String,
      borrowedAt: _asDateTime(map['borrowed_at'])!,
      returnedAt: _asDateTime(map['returned_at']),
      itemType: (map['item_type'] as String?) == 'vinyl'
          ? ItemType.vinyl
          : ItemType.cd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': albumId,
      'borrowed_by_user_id': borrowedByUserId,
      'borrowed_at': borrowedAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'item_type': itemType == ItemType.cd ? 'cd' : 'vinyl',
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
