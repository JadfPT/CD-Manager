import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../favorites/application/favorite_providers.dart';
import '../../application/artist_providers.dart';

class ArtistsPage extends ConsumerWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Artistas')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(artistsProvider);
          await ref.read(artistsProvider.future);
        },
        child: artistsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(artistsProvider),
                ),
              ),
            ],
          ),
          data: (artists) {
            if (artists.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const AppEmptyState(
                      title: 'Sem artistas',
                      subtitle: 'Ainda não existem artistas registados.',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: artists.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final artist = artists[index];
                final isFavoriteArtistAsync = ref.watch(isFavoriteArtistProvider(artist.id));
                final isFavoriteArtist = isFavoriteArtistAsync.valueOrNull ?? false;
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isFavoriteArtist
                            ? 'Remover artista dos favoritos'
                            : 'Adicionar artista aos favoritos',
                        icon: Icon(
                          isFavoriteArtist ? Icons.star : Icons.star_border,
                          color: isFavoriteArtist ? Colors.amber : null,
                        ),
                        onPressed: () async {
                          try {
                            if (isFavoriteArtist) {
                              await ref.read(favoriteActionsProvider).removeArtist(artist.id);
                            } else {
                              await ref.read(favoriteActionsProvider).addArtist(artist.id);
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavoriteArtist
                                      ? '⭐ Artista removido dos favoritos'
                                      : '⭐ Artista adicionado aos favoritos',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao atualizar artista favorito: $e')),
                            );
                          }
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/artists/${artist.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
