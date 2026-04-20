import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/artist.dart';
import '../../../shared/models/item_type.dart';
import '../../../shared/models/user_favorite_album.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/repositories/favorite_repository.dart';

class FavoriteItemKey {
  const FavoriteItemKey({
    required this.itemId,
    required this.itemType,
  });

  final int itemId;
  final ItemType itemType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteItemKey &&
        other.itemId == itemId &&
        other.itemType == itemType;
  }

  @override
  int get hashCode => Object.hash(itemId, itemType);
}

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

final favoriteItemsProvider = FutureProvider<List<AlbumListItem>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listFavoriteAlbumItemsForCurrentUser();
});

final favoriteArtistsProvider = FutureProvider<List<Artist>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listFavoriteArtistsForCurrentUser();
});

final wishlistProvider = FutureProvider<List<WishlistItem>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listWishlistEntriesForCurrentUser();
});

final adminWishlistProvider = FutureProvider<List<WishlistItem>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.listAllWishlistEntriesForAdmin();
});

final isFavoriteAlbumProvider = FutureProvider.family<bool, int>((ref, albumId) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.isFavorite(albumId);
});

final isFavoriteItemProvider =
    FutureProvider.family<bool, FavoriteItemKey>((ref, key) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.isFavorite(key.itemId, itemType: key.itemType);
});

final isFavoriteArtistProvider = FutureProvider.family<bool, int>((ref, artistId) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.isFavoriteArtist(artistId);
});

final favoriteActionsProvider = Provider<FavoriteActions>((ref) {
  return FavoriteActions(ref);
});

class FavoriteActions {
  const FavoriteActions(this._ref);

  final Ref _ref;

  Future<void> add(int albumId, {ItemType itemType = ItemType.cd}) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.addFavorite(albumId, itemType: itemType);
    _invalidateItemState(albumId, itemType);
  }

  Future<void> remove(int albumId, {ItemType itemType = ItemType.cd}) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.removeFavorite(albumId, itemType: itemType);
    _invalidateItemState(albumId, itemType);
  }

  Future<void> addArtist(int artistId) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.addFavoriteArtist(artistId);
    _ref.invalidate(favoriteArtistsProvider);
    _ref.invalidate(isFavoriteArtistProvider(artistId));
  }

  Future<void> removeArtist(int artistId) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.removeFavoriteArtist(artistId);
    _ref.invalidate(favoriteArtistsProvider);
    _ref.invalidate(isFavoriteArtistProvider(artistId));
  }

  Future<void> createWishlistItem({
    required String title,
    required ItemType itemType,
    int? artistId,
    String? artistName,
    String? formatEdition,
    String? notes,
  }) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.createWishlistItem(
      title: title,
      itemType: itemType,
      artistId: artistId,
      artistName: artistName,
      formatEdition: formatEdition,
      notes: notes,
    );
    _ref.invalidate(wishlistProvider);
    _ref.invalidate(adminWishlistProvider);
  }

  Future<void> removeWishlist(WishlistItem item) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.deleteWishlistItem(item);
    _ref.invalidate(wishlistProvider);
    _ref.invalidate(adminWishlistProvider);
  }

  Future<void> deleteWishlistItemAsAdmin(WishlistItem item) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.deleteWishlistItemAsAdmin(item);
    _ref.invalidate(wishlistProvider);
    _ref.invalidate(adminWishlistProvider);
  }

  Future<void> updateWishlistStatus({
    required WishlistItem item,
    required WishlistStatus status,
  }) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.updateWishlistStatus(item: item, status: status);
    _ref.invalidate(wishlistProvider);
    _ref.invalidate(adminWishlistProvider);
  }

  Future<void> convertWishlistToCollection({
    required WishlistItem item,
    required int artistId,
  }) async {
    final repository = _ref.read(favoriteRepositoryProvider);
    await repository.convertWishlistItemToCollection(
      item: item,
      artistId: artistId,
    );
    _ref.invalidate(wishlistProvider);
    _ref.invalidate(adminWishlistProvider);
  }

  void _invalidateItemState(int albumId, ItemType itemType) {
    _ref.invalidate(favoriteAlbumLinksProvider);
    _ref.invalidate(favoriteAlbumIdsProvider);
    _ref.invalidate(favoriteAlbumItemsProvider);
    _ref.invalidate(favoriteItemsProvider);
    _ref.invalidate(isFavoriteAlbumProvider(albumId));
    _ref.invalidate(
      isFavoriteItemProvider(FavoriteItemKey(itemId: albumId, itemType: itemType)),
    );
  }
}
