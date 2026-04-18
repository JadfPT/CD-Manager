import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/user_favorite_album.dart';
import '../../../shared/repositories/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

final favoriteAlbumLinksProvider = FutureProvider<List<UserFavoriteAlbum>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listFavoritesForCurrentUser();
});

final favoriteAlbumIdsProvider = FutureProvider<List<int>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listFavoriteAlbumIdsForCurrentUser();
});

final favoriteAlbumItemsProvider = FutureProvider<List<AlbumListItem>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listFavoriteAlbumItemsForCurrentUser();
});

final isFavoriteAlbumProvider = FutureProvider.family<bool, int>((ref, albumId) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.isFavorite(albumId);
});

final favoriteActionsProvider = Provider<FavoriteActions>((ref) {
  return FavoriteActions(ref);
});

class FavoriteActions {
  const FavoriteActions(this._ref);

  final Ref _ref;

  Future<void> add(int albumId) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.addFavorite(albumId);
    _ref.invalidate(favoriteAlbumLinksProvider);
    _ref.invalidate(favoriteAlbumIdsProvider);
    _ref.invalidate(favoriteAlbumItemsProvider);
    _ref.invalidate(isFavoriteAlbumProvider(albumId));
  }

  Future<void> remove(int albumId) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.removeFavorite(albumId);
    _ref.invalidate(favoriteAlbumLinksProvider);
    _ref.invalidate(favoriteAlbumIdsProvider);
    _ref.invalidate(favoriteAlbumItemsProvider);
    _ref.invalidate(isFavoriteAlbumProvider(albumId));
  }
}
