import 'package:flutter/material.dart';
import '../../../../shared/models/album_list_item.dart';
import 'album_cover.dart';
import 'shelf_status_chip.dart';

class AlbumListTile extends StatelessWidget {
  const AlbumListTile({
    required this.item,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final AlbumListItem item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlbumCover(
                coverUrl: item.coverUrl,
                title: item.title,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.artistName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (item.artistGenreText != null &&
                        item.artistGenreText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.artistGenreText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '#${item.albumId}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        ShelfStatusChip(onShelf: item.onShelf),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: colors.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
