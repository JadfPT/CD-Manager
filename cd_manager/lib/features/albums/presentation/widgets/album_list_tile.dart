import 'package:flutter/material.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/item_type.dart';
import 'album_cover.dart';
import 'shelf_status_chip.dart';

class AlbumListTile extends StatelessWidget {
  const AlbumListTile({
    required this.item,
    required this.onTap,
    this.onArtistTap,
    this.trailing,
    super.key,
  });

  final AlbumListItem item;
  final VoidCallback onTap;
  final VoidCallback? onArtistTap;
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AlbumCover(
                    coverUrl: item.coverUrl,
                    title: item.title,
                    size: 72,
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onArtistTap,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundImage: item.artistImageUrl == null ||
                                    item.artistImageUrl!.trim().isEmpty
                                ? null
                                : NetworkImage(item.artistImageUrl!.trim()),
                            child: item.artistImageUrl == null ||
                                    item.artistImageUrl!.trim().isEmpty
                                ? Text(
                                    item.artistName.isNotEmpty
                                        ? item.artistName[0].toUpperCase()
                                        : '?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                        _InfoBadge(
                          label: '#${item.albumId}',
                          foregroundColor: colors.onSurface,
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                        _InfoBadge(
                          label: item.itemType == ItemType.cd ? 'CD' : 'VINIL',
                          foregroundColor:
                              item.itemType == ItemType.cd ? Colors.blue.shade100 : Colors.purple.shade100,
                          backgroundColor:
                              item.itemType == ItemType.cd ? Colors.blue.withValues(alpha: 0.28) : Colors.purple.withValues(alpha: 0.28),
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
