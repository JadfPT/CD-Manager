import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../albums/presentation/widgets/album_list_tile.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do artista')),
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
                    Text(
                      artist.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (artist.genreText != null && artist.genreText!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          artist.genreText!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
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
                            onTap: () => context.push('/albums/${item.albumId}', extra: item.itemType),
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



