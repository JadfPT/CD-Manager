import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/albums/application/album_providers.dart';
import '../../../../features/artists/application/artist_providers.dart';
import '../../../../features/favorites/application/favorite_providers.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/artist.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/app_feedback.dart';

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
  bool _isRolling = false;
  int _resultVersion = 0;

  AlbumListItem? _pickedItem;
  Artist? _pickedArtist;
  String? _statusText;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = _favoritesOnly
        ? ref.watch(favoriteItemsProvider)
        : ref.watch(albumListItemsProvider(const AlbumFilters()));
    final artistsAsync = _favoritesOnly
        ? ref.watch(favoriteArtistsProvider)
        : ref.watch(artistsProvider);

    final possibleCount = _possibleResultsCount(
      items: itemsAsync.valueOrNull ?? const <AlbumListItem>[],
      artists: artistsAsync.valueOrNull ?? const <Artist>[],
    );

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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: possibleCount == 0
                          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.12)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        possibleCount == 1
                            ? '1 resultado possível com os filtros atuais'
                            : '$possibleCount resultados possíveis com os filtros atuais',
                        key: ValueKey<int>(possibleCount),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isRolling || possibleCount == 0
                          ? null
                          : () async {
                              await _drawRandom(ref);
                            },
                      icon: _isRolling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.casino_outlined),
                      label: Text(_isRolling ? 'A sortear...' : 'Sortear'),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Text(
                    _statusText!,
                    key: ValueKey(_resultVersion),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          if (_pickedItem != null)
            const SizedBox(height: 24),
          if (_pickedItem != null)
            TweenAnimationBuilder<double>(
              key: ValueKey('item-${_pickedItem!.albumId}-$_resultVersion'),
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: _SpotifyLikeAlbumResult(item: _pickedItem!),
            ),
          if (_pickedArtist != null)
            TweenAnimationBuilder<double>(
              key: ValueKey('artist-${_pickedArtist!.id}-$_resultVersion'),
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: _SpotifyLikeArtistResult(artist: _pickedArtist!),
            ),
        ],
      ),
    );
  }

  int _possibleResultsCount({
    required List<AlbumListItem> items,
    required List<Artist> artists,
  }) {
    switch (_typeFilter) {
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

  Future<void> _drawRandom(WidgetRef ref) async {
    setState(() {
      _isRolling = true;
      _pickedItem = null;
      _pickedArtist = null;
      _statusText = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));

      final items = _favoritesOnly
          ? await ref.read(favoriteItemsProvider.future)
          : await ref.read(albumListItemsProvider(const AlbumFilters()).future);
      final artists = _favoritesOnly
          ? await ref.read(favoriteArtistsProvider.future)
          : await ref.read(artistsProvider.future);

      final filteredItems = switch (_typeFilter) {
        RandomTypeFilter.cd =>
          items.where((item) => item.itemType == ItemType.cd).toList(),
        RandomTypeFilter.vinyl =>
          items.where((item) => item.itemType == ItemType.vinyl).toList(),
        RandomTypeFilter.artist => <AlbumListItem>[],
        RandomTypeFilter.all => items,
      };

      if (_typeFilter == RandomTypeFilter.artist) {
        if (artists.isEmpty) {
          setState(() {
            _statusText = 'Sem artistas para sortear com os filtros atuais.';
            _isRolling = false;
          });
          if (mounted) {
            AppFeedback.info(context, 'Sem artistas com os filtros atuais.');
          }
          return;
        }

        final picked = artists[_rng.nextInt(artists.length)];
        setState(() {
          _pickedArtist = picked;
          _statusText = 'Saiu artista!';
          _resultVersion++;
          _isRolling = false;
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
            _isRolling = false;
          });
          if (mounted) {
            AppFeedback.info(context, 'Ajusta os filtros para fazer sorteio.');
          }
          return;
        }

        final kind = choices[_rng.nextInt(choices.length)];
        if (kind == 'artist') {
          final picked = artists[_rng.nextInt(artists.length)];
          setState(() {
            _pickedArtist = picked;
            _statusText = 'Saiu artista!';
            _resultVersion++;
            _isRolling = false;
          });
          return;
        }
      }

      if (filteredItems.isEmpty) {
        setState(() {
          _statusText = 'Sem itens para sortear com os filtros atuais.';
          _isRolling = false;
        });
        if (mounted) {
          AppFeedback.info(context, 'Sem itens com os filtros atuais.');
        }
        return;
      }

      final picked = filteredItems[_rng.nextInt(filteredItems.length)];
      setState(() {
        _pickedItem = picked;
        _statusText = 'Saiu item!';
        _resultVersion++;
        _isRolling = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Erro ao sortear: $e';
        _isRolling = false;
      });
      if (mounted) {
        AppFeedback.error(context, 'Erro ao sortear item random: $e');
      }
    }
  }
}

class _SpotifyLikeAlbumResult extends StatelessWidget {
  const _SpotifyLikeAlbumResult({
    required this.item,
  });

  final AlbumListItem item;

  @override
  Widget build(BuildContext context) {
    final typeColor = item.itemType == ItemType.cd ? Colors.cyan : Colors.purple;
    final typeText = item.itemType == ItemType.cd ? 'CD' : 'Vinil';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(
          '/albums/${item.albumId}?type=${item.itemType.value}',
          extra: item.itemType,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: (item.coverUrl != null && item.coverUrl!.trim().isNotEmpty)
                      ? Image.network(
                          item.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _coverFallback(context),
                        )
                      : _coverFallback(context),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      typeText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.album, size: 42)),
    );
  }
}

class _SpotifyLikeArtistResult extends StatelessWidget {
  const _SpotifyLikeArtistResult({
    required this.artist,
  });

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/artists/${artist.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                    ? null
                    : NetworkImage(artist.imageUrl!.trim()),
                child: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                    ? Text(
                        artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist.genreText == null || artist.genreText!.trim().isEmpty
                          ? 'Sem género'
                          : artist.genreText!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
