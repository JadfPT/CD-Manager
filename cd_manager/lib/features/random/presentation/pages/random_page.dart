import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/albums/application/album_providers.dart';
import '../../../../features/artists/application/artist_providers.dart';
import '../../../../features/favorites/application/favorite_providers.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/artist.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/application/ui_action_executor.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../application/random_controller.dart';
import '../../application/random_models.dart';

class RandomPage extends ConsumerStatefulWidget {
  const RandomPage({super.key});

  @override
  ConsumerState<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends ConsumerState<RandomPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomControllerProvider);

    final itemsAsync = state.favoritesOnly
        ? ref.watch(favoriteItemsProvider)
        : ref.watch(albumListItemsProvider(const AlbumFilters()));
    final artistsAsync = state.favoritesOnly
        ? ref.watch(favoriteArtistsProvider)
        : ref.watch(artistsProvider);

    final possibleCount = ref.read(randomServiceProvider).possibleResultsCount(
          typeFilter: state.typeFilter,
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
                    selected: {state.typeFilter},
                    onSelectionChanged: (selection) {
                      ref
                          .read(randomControllerProvider.notifier)
                          .setTypeFilter(selection.first);
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
                    value: state.favoritesOnly,
                    onChanged: (value) {
                      ref.read(randomControllerProvider.notifier).setFavoritesOnly(value);
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
                      onPressed: state.isRolling || possibleCount == 0
                          ? null
                          : () async {
                              final success = await UiActionExecutor.run(
                                context,
                                actionName: 'random_draw',
                                logCategory: 'random.ui',
                                action: () =>
                                    ref.read(randomControllerProvider.notifier).draw(),
                                errorMessage: 'Erro ao sortear item random.',
                              );

                              if (!success || !context.mounted) return;

                              final latest = ref.read(randomControllerProvider);
                              if (latest.statusText ==
                                      'Sem artistas para sortear com os filtros atuais.' ||
                                  latest.statusText ==
                                      'Nada para sortear com os filtros atuais.' ||
                                  latest.statusText ==
                                      'Sem itens para sortear com os filtros atuais.') {
                                AppFeedback.info(context, latest.statusText!);
                              }
                            },
                      icon: state.isRolling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.casino_outlined),
                      label: Text(state.isRolling ? 'A sortear...' : 'Sortear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.statusText != null)
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
                    state.statusText!,
                    key: ValueKey(state.resultVersion),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          if (state.pickedItem != null)
            const SizedBox(height: 24),
          if (state.pickedItem != null)
            TweenAnimationBuilder<double>(
              key: ValueKey('item-${state.pickedItem!.albumId}-${state.resultVersion}'),
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: _SpotifyLikeAlbumResult(item: state.pickedItem!),
            ),
          if (state.pickedArtist != null)
            TweenAnimationBuilder<double>(
              key: ValueKey('artist-${state.pickedArtist!.id}-${state.resultVersion}'),
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: _SpotifyLikeArtistResult(artist: state.pickedArtist!),
            ),
        ],
      ),
    );
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
                  child: AppNetworkImage(
                    imageUrl: item.coverUrl,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: _coverFallback(context),
                  ),
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
                child: AppNetworkImage(
                  imageUrl: artist.imageUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(999),
                  placeholder: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Text(
                      artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                    ),
                  ),
                ),
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
