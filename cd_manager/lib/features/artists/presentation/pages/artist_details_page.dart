import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../albums/presentation/widgets/album_list_tile.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
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
                AppFeedback.success(
                  context,
                  isFavoriteArtist
                      ? 'Artista removido dos favoritos.'
                      : 'Artista adicionado aos favoritos.',
                );
              } catch (e) {
                if (!context.mounted) return;
                AppFeedback.error(
                  context,
                  'Não foi possível atualizar artista favorito: $e',
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
        loading: () => const _ArtistDetailsSkeleton(),
        error: (error, stackTrace) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(artistDetailsProvider(artistId)),
        ),
        data: (details) {
          final artist = details.artist;
          final albums = details.albums;
          final cdCount = albums.where((item) => item.itemType.name == 'cd').length;
          final vinylCount = albums.where((item) => item.itemType.name == 'vinyl').length;

          if (artist == null) {
            return const AppEmptyState(
              title: 'Artista não encontrado',
              subtitle: 'Pode ter sido removido.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              AppSectionCard(
                title: artist.name,
                subtitle: artist.genreText?.trim().isNotEmpty == true
                    ? artist.genreText
                    : 'Sem género definido',
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                      ? null
                      : NetworkImage(artist.imageUrl!.trim()),
                  child: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                      ? Text(
                          artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                          style: Theme.of(context).textTheme.titleLarge,
                        )
                      : null,
                ),
                trailing: Icon(
                  Icons.graphic_eq,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CountChip(label: 'Total ${albums.length}'),
                    _CountChip(label: 'CDs $cdCount'),
                    _CountChip(label: 'Vinis $vinylCount'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (albums.isEmpty)
                const SizedBox(
                  height: 360,
                  child: AppEmptyState(
                    title: 'Sem itens para este artista',
                    subtitle: 'Ainda não existem CDs ou vinis associados.',
                    icon: Icons.library_music_outlined,
                  ),
                )
              else
                ...albums.map(
                  (item) => AlbumListTile(
                    item: item,
                    onTap: () => context.push(
                      '/albums/${item.albumId}?type=${item.itemType.value}',
                      extra: item.itemType,
                    ),
                    onArtistTap: () => context.push('/artists/${item.artistId}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ArtistDetailsSkeleton extends StatelessWidget {
  const _ArtistDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SkeletonBox(width: 58, height: 58, radius: 999),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 180, height: 16),
                        SizedBox(height: 8),
                        SkeletonBox(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          AlbumTileSkeleton(),
          AlbumTileSkeleton(),
          AlbumTileSkeleton(),
        ],
      ),
    );
  }
}



