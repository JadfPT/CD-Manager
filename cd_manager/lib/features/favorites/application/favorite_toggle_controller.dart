import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'favorite_providers.dart';

final favoriteToggleControllerProvider =
    StateNotifierProvider.family<FavoriteToggleController, AsyncValue<void>, int>(
  (ref, albumId) => FavoriteToggleController(ref, albumId),
);

class FavoriteToggleController extends StateNotifier<AsyncValue<void>> {
  FavoriteToggleController(this._ref, this._albumId)
      : super(const AsyncData(null));

  final Ref _ref;
  final int _albumId;

  Future<void> toggle({required bool isFavorite}) async {
    state = const AsyncLoading();

    try {
      debugPrint('[FavoriteToggleController] toggle albumId=$_albumId isFavorite=$isFavorite');
      final actions = _ref.read(favoriteActionsProvider);
      if (isFavorite) {
        await actions.remove(_albumId);
      } else {
        await actions.add(_albumId);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final favoriteItemToggleControllerProvider =
    StateNotifierProvider.family<FavoriteItemToggleController, AsyncValue<void>, FavoriteItemKey>(
  (ref, key) => FavoriteItemToggleController(ref, key),
);

class FavoriteItemToggleController extends StateNotifier<AsyncValue<void>> {
  FavoriteItemToggleController(this._ref, this._key)
      : super(const AsyncData(null));

  final Ref _ref;
  final FavoriteItemKey _key;

  Future<void> toggle({required bool isFavorite}) async {
    state = const AsyncLoading();

    try {
      debugPrint('[FavoriteItemToggleController] toggle itemId=${_key.itemId} type=${_key.itemType.value} isFavorite=$isFavorite');
      final actions = _ref.read(favoriteActionsProvider);
      if (isFavorite) {
        await actions.remove(_key.itemId, itemType: _key.itemType);
      } else {
        await actions.add(_key.itemId, itemType: _key.itemType);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
