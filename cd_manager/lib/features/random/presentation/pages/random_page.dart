import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/albums/application/album_providers.dart';
import '../../../../features/artists/application/artist_providers.dart';
import '../../../../features/favorites/application/favorite_providers.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/artist.dart';

enum RandomTypeFilter { all, cd, vinyl, artist }

class RandomPage extends ConsumerStatefulWidget {
  const RandomPage({super.key});

  @override
  ConsumerState<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends ConsumerState<RandomPage> {
  final _rng = Random();
  RandomTypeFilter _typeFilter = RandomTypeFilter.all;
  bool _favoritesOnly = false;

  AlbumListItem? _pickedItem;
  Artist? _pickedArtist;
  String? _statusText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Random 🎲')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolhe o tipo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<RandomTypeFilter>(
                    selected: {_typeFilter},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _typeFilter = selection.first;
                      });
                    },
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: RandomTypeFilter.all, label: Text('Todos')),
                      ButtonSegment(value: RandomTypeFilter.cd, label: Text('CD')),
                      ButtonSegment(value: RandomTypeFilter.vinyl, label: Text('Vinil')),
                      ButtonSegment(value: RandomTypeFilter.artist, label: Text('Artista')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Só favoritos'),
                    subtitle: const Text('Usa apenas favoritos na seleção'),
                    value: _favoritesOnly,
                    onChanged: (value) {
                      setState(() {
                        _favoritesOnly = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _drawRandom(ref);
                      },
                      icon: const Icon(Icons.casino_outlined),
                      label: const Text('Sortear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_statusText != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _statusText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          if (_pickedItem != null)
            Card(
              child: ListTile(
                leading: Icon(
                  _pickedItem!.itemType.value == 'cd'
                      ? Icons.album_outlined
                      : Icons.album,
                ),
                title: Text(_pickedItem!.title),
                subtitle: Text('${_pickedItem!.artistName} • ${_pickedItem!.itemType.value.toUpperCase()}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/albums/${_pickedItem!.albumId}',
                  extra: _pickedItem!.itemType,
                ),
              ),
            ),
          if (_pickedArtist != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: _pickedArtist!.imageUrl == null ||
                          _pickedArtist!.imageUrl!.trim().isEmpty
                      ? null
                      : NetworkImage(_pickedArtist!.imageUrl!.trim()),
                  child: _pickedArtist!.imageUrl == null ||
                          _pickedArtist!.imageUrl!.trim().isEmpty
                      ? Text(
                          _pickedArtist!.name.isNotEmpty
                              ? _pickedArtist!.name[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(_pickedArtist!.name),
                subtitle: Text(
                  _pickedArtist!.genreText == null ||
                          _pickedArtist!.genreText!.trim().isEmpty
                      ? 'Sem género'
                      : _pickedArtist!.genreText!,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/artists/${_pickedArtist!.id}'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _drawRandom(WidgetRef ref) async {
    setState(() {
      _pickedItem = null;
      _pickedArtist = null;
      _statusText = null;
    });

    try {
      final items = _favoritesOnly
          ? await ref.read(favoriteItemsProvider.future)
          : await ref.read(
              albumListItemsProvider(
                const AlbumFilters(),
              ).future,
            );
      final artists = _favoritesOnly
          ? await ref.read(favoriteArtistsProvider.future)
          : await ref.read(artistsProvider.future);

      final filteredItems = switch (_typeFilter) {
        RandomTypeFilter.cd =>
          items.where((item) => item.itemType.value == 'cd').toList(),
        RandomTypeFilter.vinyl =>
          items.where((item) => item.itemType.value == 'vinyl').toList(),
        RandomTypeFilter.artist => <AlbumListItem>[],
        RandomTypeFilter.all => items,
      };

      if (_typeFilter == RandomTypeFilter.artist) {
        if (artists.isEmpty) {
          setState(() {
            _statusText = 'Sem artistas para sortear com os filtros atuais.';
          });
          return;
        }

        final picked = artists[_rng.nextInt(artists.length)];
        setState(() {
          _pickedArtist = picked;
          _statusText = 'Saiu artista!';
        });
        return;
      }

      if (_typeFilter == RandomTypeFilter.all) {
        final choices = <String>[];
        if (filteredItems.isNotEmpty) choices.add('item');
        if (artists.isNotEmpty) choices.add('artist');

        if (choices.isEmpty) {
          setState(() {
            _statusText = 'Nada para sortear com os filtros atuais.';
          });
          return;
        }

        final kind = choices[_rng.nextInt(choices.length)];
        if (kind == 'artist') {
          final picked = artists[_rng.nextInt(artists.length)];
          setState(() {
            _pickedArtist = picked;
            _statusText = 'Saiu artista!';
          });
          return;
        }
      }

      if (filteredItems.isEmpty) {
        setState(() {
          _statusText = 'Sem itens para sortear com os filtros atuais.';
        });
        return;
      }

      final picked = filteredItems[_rng.nextInt(filteredItems.length)];
      setState(() {
        _pickedItem = picked;
        _statusText = 'Saiu item!';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Erro ao sortear: $e';
      });
    }
  }
}
