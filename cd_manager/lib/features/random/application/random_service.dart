import 'dart:math';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/artist.dart';
import '../../../../shared/models/item_type.dart';
import 'random_models.dart';

class RandomService {
  RandomService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  int possibleResultsCount({
    required RandomTypeFilter typeFilter,
    required List<AlbumListItem> items,
    required List<Artist> artists,
  }) {
    switch (typeFilter) {
      case RandomTypeFilter.cd:
        return items.where((item) => item.itemType == ItemType.cd).length;
      case RandomTypeFilter.vinyl:
        return items.where((item) => item.itemType == ItemType.vinyl).length;
      case RandomTypeFilter.artist:
        return artists.length;
      case RandomTypeFilter.all:
        return items.length + artists.length;
    }
  }

  RandomDrawResult draw({
    required RandomTypeFilter typeFilter,
    required List<AlbumListItem> items,
    required List<Artist> artists,
  }) {
    final filteredItems = switch (typeFilter) {
      RandomTypeFilter.cd =>
        items.where((item) => item.itemType == ItemType.cd).toList(),
      RandomTypeFilter.vinyl =>
        items.where((item) => item.itemType == ItemType.vinyl).toList(),
      RandomTypeFilter.artist => <AlbumListItem>[],
      RandomTypeFilter.all => items,
    };

    if (typeFilter == RandomTypeFilter.artist) {
      if (artists.isEmpty) {
        return const RandomDrawResult(
          statusText: 'Sem artistas para sortear com os filtros atuais.',
        );
      }
      final picked = artists[_rng.nextInt(artists.length)];
      return RandomDrawResult(pickedArtist: picked, statusText: 'Saiu artista!');
    }

    if (typeFilter == RandomTypeFilter.all) {
      final choices = <String>[];
      if (filteredItems.isNotEmpty) choices.add('item');
      if (artists.isNotEmpty) choices.add('artist');

      if (choices.isEmpty) {
        return const RandomDrawResult(
          statusText: 'Nada para sortear com os filtros atuais.',
        );
      }

      final kind = choices[_rng.nextInt(choices.length)];
      if (kind == 'artist') {
        final picked = artists[_rng.nextInt(artists.length)];
        return RandomDrawResult(pickedArtist: picked, statusText: 'Saiu artista!');
      }
    }

    if (filteredItems.isEmpty) {
      return const RandomDrawResult(
        statusText: 'Sem itens para sortear com os filtros atuais.',
      );
    }

    final picked = filteredItems[_rng.nextInt(filteredItems.length)];
    return RandomDrawResult(pickedItem: picked, statusText: 'Saiu item!');
  }
}
