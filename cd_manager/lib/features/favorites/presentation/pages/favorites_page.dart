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
    final favoritesAsync = ref.watch(favoriteAlbumItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteAlbumItemsProvider);
          await ref.read(favoriteAlbumItemsProvider.future);
        },
        child: favoritesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(favoriteAlbumItemsProvider),
                ),
              ),
            ],
          ),
          data: (favorites) {
            if (favorites.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const AppEmptyState(
                      title: 'Ainda sem favoritos',
                      subtitle: 'Adiciona CDs aos favoritos a partir do detalhe do álbum.',
                      icon: Icons.favorite_outline,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return AlbumListTile(
                  item: item,
                  onTap: () => context.push('/albums/${item.albumId}', extra: item.itemType),
                  trailing: IconButton(
                    tooltip: 'Remover dos favoritos',
                    icon: const Icon(Icons.favorite),
                    onPressed: () async {
                      try {
                        await ref.read(favoriteActionsProvider).remove(item.albumId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removido dos favoritos')),
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
      ),
    );
  }
}



