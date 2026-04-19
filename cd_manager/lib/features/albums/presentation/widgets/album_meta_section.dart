import 'package:flutter/material.dart';
import '../../../../shared/models/album_detail_view.dart';
import 'shelf_status_chip.dart';

class AlbumMetaSection extends StatelessWidget {
  const AlbumMetaSection({
    required this.details,
    super.key,
  });

  final AlbumDetailsViewData details;

  @override
  Widget build(BuildContext context) {
    final album = details.album;
    final artist = details.artist;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informação do item',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoBlock(
                  label: 'ID',
                  value: '#${album.id}',
                ),
                _InfoBlock(
                  label: 'Artista ID',
                  value: '#${album.artistId}',
                ),
                if (album.formatEdition != null &&
                    album.formatEdition!.trim().isNotEmpty)
                  _InfoBlock(label: 'Formato', value: album.formatEdition!),
                if (artist.genreText != null && artist.genreText!.trim().isNotEmpty)
                  _InfoBlock(label: 'Género', value: artist.genreText!),
                ShelfStatusChip(onShelf: album.onShelf),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
