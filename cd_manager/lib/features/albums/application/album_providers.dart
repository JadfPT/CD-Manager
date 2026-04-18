import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album.dart';
import '../../../shared/models/album_detail_view.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/repositories/album_repository.dart';

class AlbumFilters {
  const AlbumFilters({
    this.searchText,
    this.onShelf,
  });

  final String? searchText;
  final bool? onShelf;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumFilters &&
        other.searchText == searchText &&
        other.onShelf == onShelf;
  }

  @override
  int get hashCode => Object.hash(searchText, onShelf);
}

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository();
});

final albumsProvider = FutureProvider.family<List<Album>, bool?>((ref, onShelf) {
  final repository = ref.watch(albumRepositoryProvider);
  return repository.listAlbums(onShelf: onShelf);
});

final albumListItemsProvider =
    FutureProvider.family<List<AlbumListItem>, AlbumFilters>((ref, filters) {
  final repository = ref.watch(albumRepositoryProvider);
  return repository.listAlbumListItems(
    searchText: filters.searchText,
    onShelf: filters.onShelf,
  );
});

final albumDetailsProvider = FutureProvider.family<AlbumDetailsViewData, int>((ref, albumId) {
  final repository = ref.watch(albumRepositoryProvider);
  return repository.getAlbumDetails(albumId);
});
