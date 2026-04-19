import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/item_type.dart';
import 'album_providers.dart';

enum AlbumShelfFilter {
  all,
  onShelf,
  outsideShelf,
}

enum ItemTypeFilter {
  all,
  cd,
  vinyl,
}

final albumSearchQueryProvider = StateProvider<String>((ref) => '');

final albumShelfFilterProvider =
    StateProvider<AlbumShelfFilter>((ref) => AlbumShelfFilter.all);

final itemTypeFilterProvider =
    StateProvider<ItemTypeFilter>((ref) => ItemTypeFilter.all);

final currentAlbumFiltersProvider = Provider<AlbumFilters>((ref) {
  final query = ref.watch(albumSearchQueryProvider);
  final shelfFilter = ref.watch(albumShelfFilterProvider);
  final typeFilter = ref.watch(itemTypeFilterProvider);

  bool? onShelf;
  switch (shelfFilter) {
    case AlbumShelfFilter.all:
      onShelf = null;
      break;
    case AlbumShelfFilter.onShelf:
      onShelf = true;
      break;
    case AlbumShelfFilter.outsideShelf:
      onShelf = false;
      break;
  }

  ItemType? itemType;
  switch (typeFilter) {
    case ItemTypeFilter.all:
      itemType = null;
      break;
    case ItemTypeFilter.cd:
      itemType = ItemType.cd;
      break;
    case ItemTypeFilter.vinyl:
      itemType = ItemType.vinyl;
      break;
  }

  return AlbumFilters(
    searchText: query,
    onShelf: onShelf,
    itemType: itemType,
  );
});

final visibleAlbumsProvider = FutureProvider<List<AlbumListItem>>((ref) {
  final filters = ref.watch(currentAlbumFiltersProvider);
  return ref.watch(albumListItemsProvider(filters).future);
});
