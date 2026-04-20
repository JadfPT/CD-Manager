import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../albums/application/album_providers.dart';
import '../../artists/application/artist_providers.dart';
import '../../favorites/application/favorite_providers.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/artist.dart';
import 'random_models.dart';
import 'random_service.dart';

final randomServiceProvider = Provider<RandomService>((ref) => RandomService());

final randomControllerProvider = StateNotifierProvider<RandomController, RandomState>(
  (ref) => RandomController(ref),
);

class RandomController extends StateNotifier<RandomState> {
  RandomController(this._ref) : super(const RandomState());

  final Ref _ref;

  void setTypeFilter(RandomTypeFilter filter) {
    state = state.copyWith(typeFilter: filter);
  }

  void setFavoritesOnly(bool value) {
    state = state.copyWith(favoritesOnly: value);
  }

  Future<void> draw() async {
    state = state.copyWith(
      isRolling: true,
      clearPickedItem: true,
      clearPickedArtist: true,
      clearStatusText: true,
    );

    try {
      AppLogger.info(
        'draw start filter=${state.typeFilter.name} favoritesOnly=${state.favoritesOnly}',
        category: 'random',
      );

      await Future<void>.delayed(const Duration(milliseconds: 450));

        final List<AlbumListItem> items = state.favoritesOnly
          ? await _ref.read(favoriteItemsProvider.future)
          : await _ref.read(albumListItemsProvider(const AlbumFilters()).future);
        final List<Artist> artists = state.favoritesOnly
          ? await _ref.read(favoriteArtistsProvider.future)
          : await _ref.read(artistsProvider.future);

      final result = _ref.read(randomServiceProvider).draw(
            typeFilter: state.typeFilter,
            items: items,
            artists: artists,
          );

      state = state.copyWith(
        pickedItem: result.pickedItem,
        pickedArtist: result.pickedArtist,
        statusText: result.statusText,
        isRolling: false,
        resultVersion: state.resultVersion + 1,
      );

      AppLogger.info(
        'draw success status="${result.statusText}"',
        category: 'random',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'draw failed',
        category: 'random',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        statusText: 'Erro ao sortear: $error',
        isRolling: false,
      );
      rethrow;
    }
  }
}
