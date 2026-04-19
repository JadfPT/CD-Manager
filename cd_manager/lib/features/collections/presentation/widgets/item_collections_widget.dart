import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/item_type.dart';
import '../../application/collection_providers.dart';

class ItemCollectionsWidget extends ConsumerWidget {
  const ItemCollectionsWidget({
    required this.itemId,
    required this.itemType,
    super.key,
  });

  final int itemId;
  final ItemType itemType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(
      itemCollectionsProvider((itemId: itemId, itemType: itemType)),
    );

    return collectionsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Erro ao carregar coleções',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      data: (collections) {
        if (collections.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Parte de ${collections.length} ${collections.length == 1 ? 'coleção' : 'coleções'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: collections
                    .map(
                      (collection) => _CollectionChip(
                        collectionId: collection.collectionId,
                        collectionName: collection.collectionName,
                        position: collection.position,
                        label: collection.label,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({
    required this.collectionId,
    required this.collectionName,
    this.position,
    this.label,
  });

  final int collectionId;
  final String collectionName;
  final int? position;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (position != null) '#$position',
      if (label != null && label!.trim().isNotEmpty) label!,
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/collections/$collectionId'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.collections_bookmark, size: 16, color: Colors.teal),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      collectionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.teal.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
