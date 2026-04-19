import 'item_type.dart';

class AlbumListItem {
  const AlbumListItem({
    required this.albumId,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.artistGenreText,
    this.artistImageUrl,
    required this.onShelf,
    required this.coverUrl,
    required this.createdAt,
    this.isFavorite = false,
    this.hasUserNote = false,
    this.loanId,
    this.itemType = ItemType.cd,
  });

  final int albumId;
  final String title;
  final int artistId;
  final String artistName;
  final String? artistGenreText;
  final String? artistImageUrl;
  final bool onShelf;
  final String? coverUrl;
  final DateTime? createdAt;
  final bool isFavorite;
  final bool hasUserNote;
  final int? loanId;
  final ItemType itemType;

  AlbumListItem copyWith({
    bool? isFavorite,
    bool? hasUserNote,
    int? loanId,
    ItemType? itemType,
  }) {
    return AlbumListItem(
      albumId: albumId,
      title: title,
      artistId: artistId,
      artistName: artistName,
      artistGenreText: artistGenreText,
      artistImageUrl: artistImageUrl,
      onShelf: onShelf,
      coverUrl: coverUrl,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      hasUserNote: hasUserNote ?? this.hasUserNote,
      loanId: loanId ?? this.loanId,
      itemType: itemType ?? this.itemType,
    );
  }
}
