import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album_list_item.dart';
import 'album_providers.dart';

enum AlbumShelfFilter {
  all,
  onShelf,
  outsideShelf,
}

final albumSearchQueryProvider = StateProvider<String>((ref) => '');

final albumShelfFilterProvider =
    StateProvider<AlbumShelfFilter>((ref) => AlbumShelfFilter.all);

final currentAlbumFiltersProvider = Provider<AlbumFilters>((ref) {
  final query = ref.watch(albumSearchQueryProvider);
  final shelfFilter = ref.watch(albumShelfFilterProvider);

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

  return AlbumFilters(
    searchText: query,
    onShelf: onShelf,
  );
});

final visibleAlbumsProvider = FutureProvider<List<AlbumListItem>>((ref) {
  final filters = ref.watch(currentAlbumFiltersProvider);
  return ref.watch(albumListItemsProvider(filters).future);
});
