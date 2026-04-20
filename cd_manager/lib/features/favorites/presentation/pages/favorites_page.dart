import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/models/wishlist_item.dart';
import '../../../../shared/models/artist.dart';
import '../../../albums/presentation/widgets/album_list_tile.dart';
import '../../../artists/application/artist_providers.dart';
import '../../application/favorite_providers.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favoritos'),
          actions: [
            IconButton(
              tooltip: 'Random',
              onPressed: () => context.push('/random'),
              icon: const Icon(Icons.casino_outlined),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.favorite), text: 'Itens'),
                  Tab(icon: Icon(Icons.star), text: 'Artistas'),
                  Tab(icon: Icon(Icons.push_pin), text: 'Wishlist'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoriteItemsTab(),
            _FavoriteArtistsTab(),
            _WishlistTab(),
          ],
        ),
      ),
    );
  }
}

class _FavoriteItemsTab extends ConsumerWidget {
  const _FavoriteItemsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteItemsAsync = ref.watch(favoriteItemsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(favoriteItemsProvider);
        await ref.read(favoriteItemsProvider.future);
      },
      child: favoriteItemsAsync.when(
        loading: () => const _AlwaysScrollable(child: _LoadingListBlock()),
        error: (error, _) => _AlwaysScrollable(
          child: AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(favoriteItemsProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _AlwaysScrollable(
              child: AppEmptyState(
                title: 'Sem itens favoritos',
                subtitle: 'Adiciona CDs e vinis aos favoritos.',
                icon: Icons.favorite_outline,
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AlbumListTile(
                item: item,
                onTap: () => context.push(
                  '/albums/${item.albumId}?type=${item.itemType.value}',
                  extra: item.itemType,
                ),
                onArtistTap: () => context.push('/artists/${item.artistId}'),
                trailing: IconButton(
                  tooltip: 'Remover dos favoritos',
                  icon: const Icon(Icons.favorite),
                  onPressed: () async {
                    try {
                      await ref.read(favoriteActionsProvider).remove(
                            item.albumId,
                            itemType: item.itemType,
                          );
                      if (!context.mounted) return;
                      AppFeedback.success(context, 'Item removido dos favoritos.');
                    } catch (e) {
                      if (!context.mounted) return;
                      AppFeedback.error(
                        context,
                        'Não foi possível remover favorito: $e',
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteArtistsTab extends ConsumerWidget {
  const _FavoriteArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteArtistsAsync = ref.watch(favoriteArtistsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(favoriteArtistsProvider);
        await ref.read(favoriteArtistsProvider.future);
      },
      child: favoriteArtistsAsync.when(
        loading: () => const _AlwaysScrollable(child: _LoadingListBlock()),
        error: (error, _) => _AlwaysScrollable(
          child: AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(favoriteArtistsProvider),
          ),
        ),
        data: (artists) {
          if (artists.isEmpty) {
            return const _AlwaysScrollable(
              child: AppEmptyState(
                title: 'Sem artistas favoritos',
                subtitle: 'Marca artistas como favoritos para aparecerem aqui.',
                icon: Icons.star_outline,
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                        ? null
                        : NetworkImage(artist.imageUrl!.trim()),
                    child: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                        ? Text(artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(artist.name),
                  subtitle: Text(
                    artist.genreText == null || artist.genreText!.trim().isEmpty
                        ? 'Sem género'
                        : artist.genreText!,
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover artista favorito',
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: () async {
                      try {
                        await ref.read(favoriteActionsProvider).removeArtist(artist.id);
                        if (!context.mounted) return;
                        AppFeedback.success(
                          context,
                          'Artista removido dos favoritos.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        AppFeedback.error(
                          context,
                          'Não foi possível remover artista favorito: $e',
                        );
                      }
                    },
                  ),
                  onTap: () => context.push('/artists/${artist.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WishlistTab extends ConsumerWidget {
  const _WishlistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final artists = ref.watch(artistsProvider).valueOrNull ?? const [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(wishlistProvider);
        await ref.read(wishlistProvider.future);
      },
      child: wishlistAsync.when(
        loading: () => const _AlwaysScrollable(child: _LoadingListBlock()),
        error: (error, _) => _AlwaysScrollable(
          child: AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(wishlistProvider),
          ),
        ),
        data: (items) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => _openCreateWishlistSheet(context, ref, artists),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo item wishlist'),
                ),
              ),
              if (items.isEmpty)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: const AppEmptyState(
                    title: 'Wishlist vazia',
                    subtitle: 'Adiciona itens à wishlist para os acompanhar aqui.',
                    icon: Icons.push_pin_outlined,
                  ),
                )
              else
                ...items.map(
                  (item) => _WishlistCard(
                    item: item,
                    onRemove: () async {
                      try {
                        await ref.read(favoriteActionsProvider).removeWishlist(item);
                        if (!context.mounted) return;
                        AppFeedback.success(context, 'Item removido da wishlist.');
                      } catch (e) {
                        if (!context.mounted) return;
                        AppFeedback.error(
                          context,
                          'Não foi possível remover item da wishlist: $e',
                        );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreateWishlistSheet(
    BuildContext context,
    WidgetRef ref,
    List<Artist> artists,
  ) async {
    final titleController = TextEditingController();
    final freeArtistController = TextEditingController();
    final formatController = TextEditingController();
    final notesController = TextEditingController();

    ItemType selectedType = ItemType.cd;
    int? selectedArtistId;
    bool useFreeArtistName = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedArtist = selectedArtistId != null
                ? artists.cast<Artist?>().firstWhere((a) => a?.id == selectedArtistId, orElse: () => null)
                : null;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo item',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preenche os dados do item da wishlist',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wishlist',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: 'Título *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SegmentedButton<ItemType>(
                              segments: const [
                                ButtonSegment(value: ItemType.cd, label: Text('CD')),
                                ButtonSegment(value: ItemType.vinyl, label: Text('Vinil')),
                              ],
                              selected: {selectedType},
                              onSelectionChanged: (value) {
                                setSheetState(() {
                                  selectedType = value.first;
                                });
                              },
                              showSelectedIcon: false,
                            ),
                            const SizedBox(height: 14),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: useFreeArtistName,
                              title: const Text('Usar nome de artista livre'),
                              onChanged: (value) {
                                setSheetState(() {
                                  useFreeArtistName = value;
                                  if (value) selectedArtistId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            if (!useFreeArtistName)
                              Row(
                                children: [
                                  Expanded(
                                    child: _ArtistSelectorField(
                                      selectedArtist: selectedArtist,
                                      onTap: () async {
                                        final selectedId = await _showArtistPicker(
                                          context,
                                          artists,
                                        );
                                        if (selectedId == null) return;
                                        if (!context.mounted) return;
                                        setSheetState(() {
                                          selectedArtistId = selectedId;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    tooltip: 'Novo artista',
                                    onPressed: () async {
                                      await context.push('/admin/artists/new');
                                      ref.invalidate(artistsProvider);
                                    },
                                    icon: const Icon(Icons.person_add_alt_1),
                                  ),
                                ],
                              )
                            else
                              TextField(
                                controller: freeArtistController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome do artista',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: formatController,
                              decoration: const InputDecoration(
                                labelText: 'Formato / Edição (opcional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Notas (opcional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final title = titleController.text.trim();
                                  final artistName = freeArtistController.text.trim();
                                  if (title.isEmpty) {
                                    AppFeedback.info(
                                      context,
                                      'Título é obrigatório.',
                                    );
                                    return;
                                  }
                                  if (selectedArtistId == null && artistName.isEmpty) {
                                    AppFeedback.info(
                                      context,
                                      'Seleciona um artista ou indica nome livre.',
                                    );
                                    return;
                                  }

                                  try {
                                    await ref.read(favoriteActionsProvider).createWishlistItem(
                                          title: title,
                                          itemType: selectedType,
                                          artistId: selectedArtistId,
                                          artistName: artistName,
                                          formatEdition: formatController.text.trim(),
                                          notes: notesController.text.trim(),
                                        );

                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                    AppFeedback.success(
                                      context,
                                      'Item adicionado à wishlist.',
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    AppFeedback.error(
                                      context,
                                      'Não foi possível criar item da wishlist: $e',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Criar item'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    freeArtistController.dispose();
    formatController.dispose();
    notesController.dispose();
  }

  Future<int?> _showArtistPicker(
    BuildContext context,
    List<Artist> artists,
  ) async {
    final queryController = TextEditingController();
    var query = '';

    final selectedArtistId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredArtists = artists.where((artist) {
              if (query.trim().isEmpty) return true;
              return artist.name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Pesquisar artista...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        query = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: filteredArtists.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sem artistas para esta pesquisa'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredArtists.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final artist = filteredArtists[index];
                              return ListTile(
                                title: Text(artist.name),
                                subtitle: artist.genreText == null || artist.genreText!.trim().isEmpty
                                    ? null
                                    : Text(artist.genreText!),
                                onTap: () => Navigator.of(sheetContext).pop(artist.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    queryController.dispose();
    return selectedArtistId;
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.item,
    required this.onRemove,
  });

  final WishlistItem item;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      WishlistStatus.pending => Colors.grey,
      WishlistStatus.approved => Colors.blue,
      WishlistStatus.converted => Colors.green,
      WishlistStatus.rejected => Colors.red,
    };

    final itemTypeLabel = item.itemType == ItemType.cd ? 'CD' : 'VINIL';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.displayArtistName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover da wishlist',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async => onRemove(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ChipTag(label: 'Wishlist', color: Colors.orange),
                _ChipTag(label: itemTypeLabel, color: Colors.purple),
                _ChipTag(label: item.status.name, color: statusColor),
                if (item.formatEdition != null && item.formatEdition!.trim().isNotEmpty)
                  _ChipTag(label: item.formatEdition!, color: Colors.teal),
              ],
            ),
            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AlwaysScrollable extends StatelessWidget {
  const _AlwaysScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: child,
        ),
      ],
    );
  }
}

class _LoadingListBlock extends StatelessWidget {
  const _LoadingListBlock();

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 8),
          AlbumTileSkeleton(),
          AlbumTileSkeleton(),
          AlbumTileSkeleton(),
        ],
      ),
    );
  }
}

class _ArtistSelectorField extends StatelessWidget {
  const _ArtistSelectorField({
    required this.selectedArtist,
    required this.onTap,
  });

  final Artist? selectedArtist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Artista',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          selectedArtist?.name ?? 'Selecionar artista',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

