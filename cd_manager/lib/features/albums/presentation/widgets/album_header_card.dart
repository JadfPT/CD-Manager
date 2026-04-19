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
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                            ? null
                            : NetworkImage(artist.imageUrl!.trim()),
                        child: artist.imageUrl == null || artist.imageUrl!.trim().isEmpty
                            ? Text(
                                artist.name.isNotEmpty
                                    ? artist.name[0].toUpperCase()
                                    : '?',
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (artist.genreText != null &&
                                artist.genreText!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  artist.genreText!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
