import 'item_type.dart';

class CollectionEntry {
  const CollectionEntry({
    required this.collectionId,
    required this.itemType,
    required this.itemId,
    this.position,
    this.label,
    required this.itemTitle,
    required this.itemArtistName,
    this.itemCoverUrl,
  });

  final int collectionId;
  final ItemType itemType;
  final int itemId;
  final int? position;
  final String? label;
  final String itemTitle;
  final String itemArtistName;
  final String? itemCoverUrl;

  factory CollectionEntry.fromMap(Map<String, dynamic> map) {
    return CollectionEntry(
      collectionId: map['collection_id'] as int,
      itemType: (map['item_type'] as String) == 'cd' ? ItemType.cd : ItemType.vinyl,
      itemId: map['item_id'] as int,
      position: map['position'] as int?,
      label: map['label'] as String?,
      itemTitle: (map['item_title'] as String?) ?? 'Item #${map['item_id']}',
      itemArtistName: (map['item_artist_name'] as String?) ?? 'Artista desconhecido',
      itemCoverUrl: map['item_cover_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collection_id': collectionId,
      'item_type': itemType == ItemType.cd ? 'cd' : 'vinyl',
      'item_id': itemId,
      'position': position,
      'label': label,
    };
  }

  CollectionEntry copyWith({
    int? collectionId,
    ItemType? itemType,
    int? itemId,
    int? position,
    String? label,
    String? itemTitle,
    String? itemArtistName,
    String? itemCoverUrl,
  }) {
    return CollectionEntry(
      collectionId: collectionId ?? this.collectionId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
      label: label ?? this.label,
      itemTitle: itemTitle ?? this.itemTitle,
      itemArtistName: itemArtistName ?? this.itemArtistName,
      itemCoverUrl: itemCoverUrl ?? this.itemCoverUrl,
    );
  }

  @override
  String toString() =>
      'CollectionEntry(collectionId: $collectionId, itemType: $itemType, itemId: $itemId, position: $position, label: $label)';
}
