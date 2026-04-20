import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/artist.dart';

enum RandomTypeFilter { all, cd, vinyl, artist }

class RandomState {
  const RandomState({
    this.typeFilter = RandomTypeFilter.all,
    this.favoritesOnly = false,
    this.isRolling = false,
    this.pickedItem,
    this.pickedArtist,
    this.statusText,
    this.resultVersion = 0,
  });

  final RandomTypeFilter typeFilter;
  final bool favoritesOnly;
  final bool isRolling;
  final AlbumListItem? pickedItem;
  final Artist? pickedArtist;
  final String? statusText;
  final int resultVersion;

  RandomState copyWith({
    RandomTypeFilter? typeFilter,
    bool? favoritesOnly,
    bool? isRolling,
    AlbumListItem? pickedItem,
    bool clearPickedItem = false,
    Artist? pickedArtist,
    bool clearPickedArtist = false,
    String? statusText,
    bool clearStatusText = false,
    int? resultVersion,
  }) {
    return RandomState(
      typeFilter: typeFilter ?? this.typeFilter,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      isRolling: isRolling ?? this.isRolling,
      pickedItem: clearPickedItem ? null : (pickedItem ?? this.pickedItem),
      pickedArtist: clearPickedArtist ? null : (pickedArtist ?? this.pickedArtist),
      statusText: clearStatusText ? null : (statusText ?? this.statusText),
      resultVersion: resultVersion ?? this.resultVersion,
    );
  }
}

class RandomDrawResult {
  const RandomDrawResult({
    this.pickedItem,
    this.pickedArtist,
    required this.statusText,
  });

  final AlbumListItem? pickedItem;
  final Artist? pickedArtist;
  final String statusText;
}
