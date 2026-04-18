import 'package:flutter/material.dart';
import '../../../../shared/models/album_detail_view.dart';
import 'album_cover.dart';

class AlbumHeaderCard extends StatelessWidget {
  const AlbumHeaderCard({
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumCover(
              coverUrl: album.coverUrl,
              title: album.title,
              size: 120,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (artist.genreText != null && artist.genreText!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        artist.genreText!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
