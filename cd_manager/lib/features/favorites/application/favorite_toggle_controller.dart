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
