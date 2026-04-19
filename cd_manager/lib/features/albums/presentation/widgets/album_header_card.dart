import 'package:flutter/material.dart';
import '../../../../shared/models/album_detail_view.dart';
import 'album_cover.dart';

class AlbumHeaderCard extends StatelessWidget {
  const AlbumHeaderCard({
    required this.details,
    required this.itemTypeLabel,
    required this.itemTypeColor,
    super.key,
  });

  final AlbumDetailsViewData details;
  final String itemTypeLabel;
  final Color itemTypeColor;

  @override
  Widget build(BuildContext context) {
    final album = details.album;
    final artist = details.artist;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              itemTypeColor.withValues(alpha: 0.12),
              colors.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlbumCover(
                    coverUrl: album.coverUrl,
                    title: album.title,
                    size: 156,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: itemTypeColor.withValues(alpha: 0.18),
                              backgroundImage: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                                  ? null
                                  : NetworkImage(artist.imageUrl!.trim()),
                              child: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                                  ? Text(
                                      artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artist.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (artist.genreText != null && artist.genreText!.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        artist.genreText!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(label: itemTypeLabel, color: itemTypeColor),
                            _Chip(
                              label: album.onShelf ? 'Na prateleira' : 'Fora da prateleira',
                              color: album.onShelf ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),
                      ],
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
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
