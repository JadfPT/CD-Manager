import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/collection_entry.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/collection_providers.dart';

class CollectionFormPage extends ConsumerStatefulWidget {
  const CollectionFormPage.create({super.key}) : collectionId = null;

  const CollectionFormPage.edit({
    required this.collectionId,
    super.key,
  });

  final int? collectionId;

  @override
  ConsumerState<CollectionFormPage> createState() => _CollectionFormPageState();
}

class _CollectionFormPageState extends ConsumerState<CollectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _loadedInitialValues = false;
  bool _allowPop = false;
  String _initialName = '';
  String _initialDescription = '';
  List<CollectionEntry> _loadedEntries = const [];
  final Set<String> _pendingRemovedItems = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;
    final isEdit = widget.collectionId != null;

    final detailsAsync = isEdit
        ? ref.watch(collectionDetailsProvider(widget.collectionId!))
        : null;

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges(isEdit),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmDiscardChanges(context, isEdit);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => _handleBackPressed(context, isEdit),
          ),
          title: Text(isEdit ? 'Editar coleção' : 'Criar coleção'),
        ),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Apenas administradores podem criar ou editar coleções.'),
              ),
            )
            : detailsAsync == null
              ? _buildForm(context, isEdit, entries: const [])
              : detailsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => AppErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(
                      collectionDetailsProvider(widget.collectionId!),
                    ),
                  ),
                  data: (details) {
                    if (isEdit && !_loadedInitialValues) {
                      _nameController.text = details.collection.name;
                      _descriptionController.text =
                          details.collection.description ?? '';
                      _initialName = details.collection.name;
                      _initialDescription = details.collection.description ?? '';
                      _loadedEntries = List<CollectionEntry>.from(details.entries);
                      _loadedInitialValues = true;
                    }
                    return _buildForm(context, isEdit, entries: details.entries);
                  },
                ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    bool isEdit, {
    required List<CollectionEntry> entries,
  }) {
    final visibleEntries = _visibleEntries(entries);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isEdit ? 'Editar coleção' : 'Nova coleção',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isEdit
              ? 'Atualize os dados da coleção'
              : 'Preencha os dados da nova coleção',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coleção',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Indica um nome para a coleção';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveCollection,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(isEdit ? Icons.save_outlined : Icons.add_outlined),
                      label: Text(
                        isEdit ? 'Guardar alterações' : 'Criar coleção',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isEdit) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itens da coleção',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (entries.isEmpty)
                    Text(
                      'Esta coleção ainda não tem itens.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  else if (visibleEntries.isEmpty)
                    Text(
                      'Todos os itens foram marcados para remover. Só serão apagados ao guardar.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleEntries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = visibleEntries[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: entry.itemCoverUrl != null &&
                                  entry.itemCoverUrl!.trim().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    entry.itemCoverUrl!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.album, size: 20),
                                ),
                          title: Text(
                            entry.itemTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${entry.itemArtistName} • ${entry.itemType.name == 'vinyl' ? 'Vinil' : 'CD'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover da coleção',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _markItemForRemoval(entry),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<CollectionEntry> _visibleEntries(List<CollectionEntry> entries) {
    return entries
        .where((entry) => !_pendingRemovedItems.contains(_entryKey(entry)))
        .toList();
  }

  String _entryKey(CollectionEntry entry) {
    return '${entry.itemType.name}:${entry.itemId}';
  }

  bool _hasUnsavedChanges(bool isEdit) {
    final nameChanged = _nameController.text.trim() != _initialName.trim();
    final descriptionChanged =
        _descriptionController.text.trim() != _initialDescription.trim();
    final hasPendingRemovals = _pendingRemovedItems.isNotEmpty;

    if (isEdit) {
      return nameChanged || descriptionChanged || hasPendingRemovals;
    }

    return _nameController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _markItemForRemoval(CollectionEntry entry) async {
    setState(() {
      _pendingRemovedItems.add(_entryKey(entry));
    });
  }

  Future<void> _handleBackPressed(BuildContext context, bool isEdit) async {
    if (!_hasUnsavedChanges(isEdit)) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    await _confirmDiscardChanges(context, isEdit);
  }

  Future<void> _confirmDiscardChanges(BuildContext context, bool isEdit) async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Vais sair sem guardar as alterações. Queres cancelar ou sair mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && context.mounted) {
      setState(() {
        _allowPop = true;
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.collectionId != null;
      int? newCollectionId;

      if (isEdit) {
        await ref.read(collectionActionsProvider).updateCollection(
          collectionId: widget.collectionId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        final removedEntries = _loadedEntries
            .where((entry) => _pendingRemovedItems.contains(_entryKey(entry)))
            .toList();

        for (final entry in removedEntries) {
          await ref.read(collectionActionsProvider).removeItemFromCollection(
            collectionId: widget.collectionId!,
            itemId: entry.itemId,
            itemType: entry.itemType,
          );
        }
      } else {
        newCollectionId = await ref.read(collectionActionsProvider).createCollection(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Coleção atualizada' : 'Coleção criada com sucesso',
          ),
        ),
      );

      // Se foi criação e não edição, oferecer adicionar itens
      if (!isEdit && newCollectionId != null) {
        await _showAddItemsDialog(context, newCollectionId);
        if (mounted) context.pop();
      } else {
        if (mounted) context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar coleção: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddItemsDialog(BuildContext context, int collectionId) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Adicionar itens'),
        content: const Text(
          'Deseja adicionar CDs ou vinis a esta coleção agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/collections/$collectionId/add-item');
            },
            child: const Text('Adicionar agora'),
          ),
        ],
      ),
    );
  }
}
