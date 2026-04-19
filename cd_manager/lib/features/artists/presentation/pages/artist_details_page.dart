import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../albums/presentation/widgets/album_list_tile.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../favorites/application/favorite_providers.dart';
import '../../application/artist_providers.dart';

class ArtistDetailsPage extends ConsumerWidget {
  const ArtistDetailsPage({
    required this.artistId,
    super.key,
  });

  final int artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(artistDetailsProvider(artistId));
    final isFavoriteArtistAsync = ref.watch(isFavoriteArtistProvider(artistId));
    final isFavoriteArtist = isFavoriteArtistAsync.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do artista'),
        actions: [
          IconButton(
            tooltip: isFavoriteArtist
                ? 'Remover artista dos favoritos'
                : 'Adicionar artista aos favoritos',
            onPressed: () async {
              try {
                if (isFavoriteArtist) {
                  await ref.read(favoriteActionsProvider).removeArtist(artistId);
                } else {
                  await ref.read(favoriteActionsProvider).addArtist(artistId);
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
            icon: Icon(
              isFavoriteArtist ? Icons.star : Icons.star_border,
              color: isFavoriteArtist ? Colors.amber : null,
            ),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(artistDetailsProvider(artistId)),
        ),
        data: (details) {
          final artist = details.artist;
          final albums = details.albums;

          if (artist == null) {
            return const AppEmptyState(
              title: 'Artista não encontrado',
              subtitle: 'Pode ter sido removido.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage:
                              artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                              ? null
                              : NetworkImage(artist.imageUrl!.trim()),
                          child: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                              ? Text(
                                  artist.name.isNotEmpty
                                      ? artist.name[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context).textTheme.titleLarge,
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
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (artist.genreText != null &&
                                  artist.genreText!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    artist.genreText!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Álbuns',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: albums.isEmpty
                    ? const AppEmptyState(
                        title: 'Sem álbuns para este artista',
                        subtitle: 'Ainda não existem CDs associados.',
                        icon: Icons.library_music_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final item = albums[index];
                          return AlbumListTile(
                            item: item,
                            onTap: () => context.push(
                              '/albums/${item.albumId}?type=${item.itemType.value}',
                              extra: item.itemType,
                            ),
                            onArtistTap: () => context.push('/artists/${item.artistId}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}



