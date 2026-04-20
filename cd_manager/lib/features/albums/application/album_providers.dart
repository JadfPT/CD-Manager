import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album.dart';
import '../../../shared/models/album_detail_view.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/item_type.dart';
import '../../../shared/repositories/album_repository.dart';
import '../../auth/application/auth_providers.dart';

class AlbumFilters {
  const AlbumFilters({
    this.searchText,
    this.onShelf,
    this.itemType,
  });

  final String? searchText;
  final bool? onShelf;
  final ItemType? itemType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumFilters &&
        other.searchText == searchText &&
        other.onShelf == onShelf &&
        other.itemType == itemType;
  }

  @override
  int get hashCode => Object.hash(searchText, onShelf, itemType);
}

class AlbumDetailsKey {
  const AlbumDetailsKey({
    required this.albumId,
    this.itemType = ItemType.cd,
  });

  final int albumId;
  final ItemType itemType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumDetailsKey &&
        other.albumId == albumId &&
        other.itemType == itemType;
  }

  @override
  int get hashCode => Object.hash(albumId, itemType);
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
  final authState = ref.watch(authProvider);
  if (authState is! AuthSuccess) {
    return Future.value(const <AlbumListItem>[]);
  }

  final repository = ref.watch(albumRepositoryProvider);
  return repository.listAllItemsUnified(
    searchText: filters.searchText,
    onShelf: filters.onShelf,
    itemTypeFilter: filters.itemType,
  );
});

final albumDetailsProvider =
    FutureProvider.family<AlbumDetailsViewData, AlbumDetailsKey>((ref, key) {
  final repository = ref.watch(albumRepositoryProvider);
  return repository.getAlbumDetails(key.albumId, itemType: key.itemType);
});
