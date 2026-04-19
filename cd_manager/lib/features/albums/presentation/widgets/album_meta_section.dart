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
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetaChip(label: 'ID', value: '#${album.id}'),
                _MetaChip(label: 'Artista ID', value: '#${album.artistId}'),
                if (album.formatEdition != null &&
                    album.formatEdition!.trim().isNotEmpty)
                  _MetaChip(label: 'Formato', value: album.formatEdition!),
                if (artist.genreText != null && artist.genreText!.trim().isNotEmpty)
                  _MetaChip(label: 'Género', value: artist.genreText!),
                ShelfStatusChip(onShelf: album.onShelf),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
