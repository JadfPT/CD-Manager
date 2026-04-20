import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_section_card.dart';

class RecentItemsSection extends StatelessWidget {
  const RecentItemsSection({required this.items, super.key});

  final List<AlbumListItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Sem itens recentes',
        subtitle: 'Adiciona CDs ou vinis para ver aqui os últimos registos.',
        icon: Icons.history,
      );
    }

    return AppSectionCard(
      title: 'Últimos adicionados',
      subtitle: 'Acesso rápido aos registos mais recentes',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => context.push(
              '/albums/${item.albumId}?type=${item.itemType.value}',
              extra: item.itemType,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppNetworkImage(
                imageUrl: item.coverUrl,
                width: 44,
                height: 44,
                placeholder: Container(
                  width: 44,
                  height: 44,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.album, size: 20),
                ),
              ),
            ),
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${item.artistName} • ${item.itemType == ItemType.cd ? 'CD' : 'Vinil'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: item.itemType == ItemType.cd
                    ? Colors.cyan.withValues(alpha: 0.16)
                    : Colors.purple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.itemType == ItemType.cd ? 'CD' : 'Vinil',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
