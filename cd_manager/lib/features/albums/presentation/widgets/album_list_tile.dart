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
    final typeLabel = item.itemType == ItemType.cd ? 'CD' : 'VINIL';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return colors.primary.withValues(alpha: 0.04);
          }
          return null;
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlbumCover(
                    coverUrl: item.coverUrl,
                    title: item.title,
                    size: 78,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$typeLabel #${item.albumId}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onArtistTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 11,
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
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.artistGenreText != null &&
                        item.artistGenreText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.artistGenreText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.88),
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoBadge(
                          label: typeLabel,
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
                    color: colors.onSurfaceVariant.withValues(alpha: 0.85),
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
