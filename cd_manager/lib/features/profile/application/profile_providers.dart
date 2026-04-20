import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../../features/albums/application/album_providers.dart';
import '../../../features/favorites/application/favorite_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/item_type.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/repositories/profile_repository.dart';

class ProfileLibraryStats {
  const ProfileLibraryStats({
    required this.cdCount,
    required this.vinylCount,
    required this.totalItemsCount,
    required this.favoriteItemsCount,
    required this.favoriteArtistsCount,
    required this.wishlistCount,
    required this.offShelfCount,
  });

  final int cdCount;
  final int vinylCount;
  final int totalItemsCount;
  final int favoriteItemsCount;
  final int favoriteArtistsCount;
  final int wishlistCount;
  final int offShelfCount;
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final currentProfileUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthSuccess) {
    return authState.user.id;
  }
  return null;
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentProfileUserIdProvider);
  if (userId == null) {
    return null;
  }

  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfileById(userId);
});

final profileLibraryStatsProvider = FutureProvider<ProfileLibraryStats>((ref) async {
  final items = await ref.watch(albumListItemsProvider(const AlbumFilters()).future);
  final favoriteItems = await ref.watch(favoriteItemsProvider.future);
  final favoriteArtists = await ref.watch(favoriteArtistsProvider.future);
  final wishlist = await ref.watch(wishlistProvider.future);

  final cdCount = items.where((item) => item.itemType == ItemType.cd).length;
  final vinylCount = items.where((item) => item.itemType == ItemType.vinyl).length;
  final offShelfCount = items.where((item) => !item.onShelf).length;

  return ProfileLibraryStats(
    cdCount: cdCount,
    vinylCount: vinylCount,
    totalItemsCount: items.length,
    favoriteItemsCount: favoriteItems.length,
    favoriteArtistsCount: favoriteArtists.length,
    wishlistCount: wishlist.length,
    offShelfCount: offShelfCount,
  );
});

final recentAddedItemsProvider = FutureProvider<List<AlbumListItem>>((ref) async {
  final items = await ref.watch(albumListItemsProvider(const AlbumFilters()).future);
  final sorted = [...items]
    ..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  return sorted.take(5).toList();
});

final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});

class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  Future<Profile> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final repository = _ref.read(profileRepositoryProvider);
    final profile = await repository.updateCurrentUserProfile(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    _ref.invalidate(currentProfileProvider);
    return profile;
  }

  Future<String> uploadAvatar({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final repository = _ref.read(profileRepositoryProvider);
    final avatarUrl = await repository.uploadAvatarForCurrentUser(
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
    _ref.invalidate(currentProfileProvider);
    return avatarUrl;
  }
}
