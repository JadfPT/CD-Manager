import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_search_field.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('CDs')),
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
                loading: () => const Center(child: CircularProgressIndicator()),
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
                            title: 'Sem CDs para mostrar',
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
                        onTap: () => context.push('/albums/${item.albumId}'),
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
