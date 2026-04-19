import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../albums/application/album_providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/collection_providers.dart';

class AddItemToCollectionPage extends ConsumerStatefulWidget {
  const AddItemToCollectionPage({
    required this.collectionId,
    super.key,
  });

  final int collectionId;

  @override
  ConsumerState<AddItemToCollectionPage> createState() =>
      _AddItemToCollectionPageState();
}

class _AddItemToCollectionPageState
    extends ConsumerState<AddItemToCollectionPage> {
  ItemType selectedType = ItemType.cd;
  AlbumListItem? pickerSelectedItem;
  final List<AlbumListItem> pendingItems = [];
  final _positionController = TextEditingController();
  final _labelController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _positionController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;

    final albumsAsync = ref.watch(
      albumListItemsProvider(AlbumFilters(itemType: selectedType)),
    );

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adicionar item')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Apenas administradores podem adicionar itens a coleções.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar item à coleção'),
      ),
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro ao carregar itens: $error'),
          ),
        ),
        data: (albums) {
          final filteredAlbums = albums
              .where((album) => album.itemType == selectedType)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Adicionar item',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione o item a adicionar à coleção',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecionar item',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<ItemType>(
                        segments: const [
                          ButtonSegment(value: ItemType.cd, label: Text('CDs')),
                          ButtonSegment(value: ItemType.vinyl, label: Text('Vinis')),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (value) {
                          setState(() {
                            selectedType = value.first;
                            pickerSelectedItem = null;
                          });
                        },
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 14),
                      if (filteredAlbums.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Nenhum ${selectedType == ItemType.cd ? 'CD' : 'vinil'} disponível',
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                            ),
                          ),
                        )
                      else
                        _ItemSelectorField(
                          selectedItem: pickerSelectedItem,
                          onTap: () async {
                            final selected = await _showItemPicker(
                              context,
                              filteredAlbums,
                            );
                            if (selected == null || !mounted) return;
                            setState(() {
                              pickerSelectedItem = selected;
                            });
                          },
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: pickerSelectedItem == null
                              ? null
                              : () {
                                  final selected = pickerSelectedItem;
                                  if (selected == null) return;
                                  final key = _itemKey(selected);
                                  final exists = pendingItems.any(
                                    (item) => _itemKey(item) == key,
                                  );
                                  if (exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Esse item já está na lista.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    pendingItems.add(selected);
                                    pickerSelectedItem = null;
                                  });
                                },
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Adicionar à lista'),
                        ),
                      ),
                      if (pendingItems.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Itens selecionados (${pendingItems.length})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = pendingItems[index];
                              return ListTile(
                                dense: true,
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: (item.coverUrl != null &&
                                              item.coverUrl!.trim().isNotEmpty)
                                          ? Image.network(
                                              item.coverUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
                                                width: 40,
                                                height: 40,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                child: const Icon(Icons.album, size: 18),
                                              ),
                                            )
                                          : Container(
                                              width: 40,
                                              height: 40,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              child: const Icon(Icons.album, size: 18),
                                            ),
                                    ),
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${item.artistName} • ${item.itemType == ItemType.cd ? 'CD' : 'Vinil'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remover da lista',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      pendingItems.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Posição inicial (opcional)',
                          hintText: 'ex: 1, 2, 3...',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (pendingItems.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Se definires posição inicial, os próximos itens serão incrementados automaticamente.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label (opcional)',
                          hintText: 'ex: Disco 1, Special Edition...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading || pendingItems.isEmpty
                              ? null
                              : _addItemsToCollection,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_outlined),
                          label: Text(
                            pendingItems.length <= 1
                                ? 'Adicionar item'
                                : 'Adicionar ${pendingItems.length} itens',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _itemKey(AlbumListItem item) {
    final type = item.itemType == ItemType.cd ? 'cd' : 'vinyl';
    return '$type:${item.albumId}';
  }

  Future<AlbumListItem?> _showItemPicker(
    BuildContext context,
    List<AlbumListItem> items,
  ) async {
    final queryController = TextEditingController();
    var query = '';

    final selectedItem = await showModalBottomSheet<AlbumListItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredItems = items.where((item) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase();
              return item.title.toLowerCase().contains(q) ||
                  item.artistName.toLowerCase().contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Pesquisar item...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        query = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sem itens para esta pesquisa'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: (item.coverUrl != null &&
                                          item.coverUrl!.trim().isNotEmpty)
                                      ? Image.network(
                                          item.coverUrl!,
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            width: 42,
                                            height: 42,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: const Icon(Icons.album, size: 18),
                                          ),
                                        )
                                      : Container(
                                          width: 42,
                                          height: 42,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          child: const Icon(Icons.album, size: 18),
                                        ),
                                ),
                                title: Text(item.title),
                                subtitle: Text(item.artistName),
                                trailing: Text(
                                  item.itemType == ItemType.cd ? 'CD' : 'Vinil',
                                ),
                                onTap: () => Navigator.of(sheetContext).pop(item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    queryController.dispose();
    return selectedItem;
  }

  Future<void> _addItemsToCollection() async {
    if (pendingItems.isEmpty) return;

    int? startPosition;
    final positionRaw = _positionController.text.trim();
    if (positionRaw.isNotEmpty) {
      startPosition = int.tryParse(positionRaw);
      if (startPosition == null || startPosition <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posição inicial inválida.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final label = _labelController.text.trim();
      var successCount = 0;
      var errorCount = 0;

      for (var index = 0; index < pendingItems.length; index++) {
        final item = pendingItems[index];
        try {
          await ref.read(collectionActionsProvider).addItemToCollection(
            collectionId: widget.collectionId,
            itemId: item.albumId,
            itemType: item.itemType,
            position: startPosition == null ? null : (startPosition + index),
            label: label,
          );
          successCount++;
        } catch (_) {
          errorCount++;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorCount == 0
                ? '$successCount ${successCount == 1 ? 'item adicionado' : 'itens adicionados'} à coleção.'
                : '$successCount adicionados, $errorCount com erro (podem já existir noutra coleção).',
          ),
        ),
      );

      if (successCount > 0) {
        setState(() {
          pendingItems.clear();
          pickerSelectedItem = null;
          _positionController.clear();
          _labelController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _ItemSelectorField extends StatelessWidget {
  const _ItemSelectorField({
    required this.selectedItem,
    required this.onTap,
  });

  final AlbumListItem? selectedItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Item',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          selectedItem == null
              ? 'Selecionar item'
              : '${selectedItem!.title} - ${selectedItem!.artistName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
