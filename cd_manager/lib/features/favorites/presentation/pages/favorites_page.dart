import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../albums/presentation/widgets/album_list_tile.dart';
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Itens'),
              Tab(icon: Icon(Icons.star), text: 'Artistas'),
              Tab(icon: Icon(Icons.push_pin), text: 'Wishlist'),
            ],
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
                onTap: () => context.push('/albums/${item.albumId}', extra: item.itemType),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item removido dos favoritos')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao remover favorito: $e')),
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
              return ListTile(
                leading: CircleAvatar(
                  child: Text(artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Artista removido dos favoritos')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao remover artista favorito: $e')),
                      );
                    }
                  },
                ),
                onTap: () => context.push('/artists/${artist.id}'),
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(wishlistProvider);
        await ref.read(wishlistProvider.future);
      },
      child: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AlwaysScrollable(
          child: AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(wishlistProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _AlwaysScrollable(
              child: AppEmptyState(
                title: 'Wishlist vazia',
                subtitle: 'Adiciona itens à wishlist para os acompanhar aqui.',
                icon: Icons.push_pin_outlined,
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
                onTap: () => context.push('/albums/${item.albumId}', extra: item.itemType),
                trailing: IconButton(
                  tooltip: 'Remover da wishlist',
                  icon: const Icon(Icons.push_pin),
                  onPressed: () async {
                    try {
                      await ref.read(favoriteActionsProvider).removeWishlist(
                            item.albumId,
                            itemType: item.itemType,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item removido da wishlist')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao remover da wishlist: $e')),
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



