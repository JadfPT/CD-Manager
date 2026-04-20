import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/album_view_providers.dart';
import '../widgets/album_list_tile.dart';

class AlbumsPage extends ConsumerStatefulWidget {
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends ConsumerState<AlbumsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(visibleAlbumsProvider);
    final filter = ref.watch(albumShelfFilterProvider);
    final typeFilter = ref.watch(itemTypeFilterProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coleção'),
        actions: [
          IconButton(
            tooltip: 'Random',
            onPressed: () => context.push('/random'),
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              tooltip: 'Criar item',
              onPressed: () async {
                final selected = await showModalBottomSheet<ItemType>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.album_outlined),
                          title: const Text('Novo CD'),
                          onTap: () => Navigator.of(context).pop(ItemType.cd),
                        ),
                        ListTile(
                          leading: const Icon(Icons.album),
                          title: const Text('Novo Vinil'),
                          onTap: () => Navigator.of(context).pop(ItemType.vinyl),
                        ),
                      ],
                    ),
                  ),
                );

                if (!context.mounted || selected == null) return;
                final typeSegment = selected == ItemType.cd ? 'cd' : 'vinyl';
                context.push('/admin/items/new/$typeSegment');
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Pesquisar por álbum ou artista',
              onChanged: (value) {
                ref.read(albumSearchQueryProvider.notifier).state = value;
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<ItemTypeFilter>(
              segments: const [
                ButtonSegment(
                  value: ItemTypeFilter.all,
                  label: Text('Todos'),
                ),
                ButtonSegment(
                  value: ItemTypeFilter.cd,
                  label: Text('CDs'),
                ),
                ButtonSegment(
                  value: ItemTypeFilter.vinyl,
                  label: Text('Vinis'),
                ),
              ],
              selected: {typeFilter},
              onSelectionChanged: (selection) {
                ref.read(itemTypeFilterProvider.notifier).state = selection.first;
              },
              showSelectedIcon: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<AlbumShelfFilter>(
              segments: const [
                ButtonSegment(
                  value: AlbumShelfFilter.all,
                  label: Text('Todos'),
                ),
                ButtonSegment(
                  value: AlbumShelfFilter.onShelf,
                  label: Text('Na prateleira'),
                ),
                ButtonSegment(
                  value: AlbumShelfFilter.outsideShelf,
                  label: Text('Fora da prateleira'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (selection) {
                ref.read(albumShelfFilterProvider.notifier).state = selection.first;
              },
              showSelectedIcon: false,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(visibleAlbumsProvider);
                await ref.read(visibleAlbumsProvider.future);
              },
              child: albumsAsync.when(
                loading: () => LoadingSkeleton(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 8),
                      AlbumTileSkeleton(),
                      AlbumTileSkeleton(),
                      AlbumTileSkeleton(),
                      AlbumTileSkeleton(),
                    ],
                  ),
                ),
                error: (error, stackTrace) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: AppErrorState(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(visibleAlbumsProvider),
                      ),
                    ),
                  ],
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: const AppEmptyState(
                            title: 'Sem itens para mostrar',
                            subtitle: 'Ajusta os filtros ou pesquisa.',
                            icon: Icons.album_outlined,
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AlbumListTile(
                        item: item,
                        onTap: () => context.push(
                          '/albums/${item.albumId}?type=${item.itemType.value}',
                          extra: item.itemType,
                        ),
                        onArtistTap: () => context.push('/artists/${item.artistId}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}




