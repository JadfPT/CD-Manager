import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/albums/application/album_providers.dart';
import '../../../../features/albums/application/album_view_providers.dart';
import '../../../../features/artists/application/artist_providers.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../shared/models/album_detail_view.dart';
import '../../../../shared/models/artist.dart';
import '../../../../shared/models/item_type.dart';

class AdminItemFormPage extends ConsumerStatefulWidget {
  const AdminItemFormPage.create({
    required this.itemType,
    super.key,
  })  : itemId = null,
        isEdit = false;

  const AdminItemFormPage.edit({
    required this.itemType,
    required this.itemId,
    super.key,
  }) : isEdit = true;

  final ItemType itemType;
  final int? itemId;
  final bool isEdit;

  @override
  ConsumerState<AdminItemFormPage> createState() => _AdminItemFormPageState();
}

class _AdminItemFormPageState extends ConsumerState<AdminItemFormPage> {
  static const List<String> _cdFormatOptions = [
    'CD',
    'CD Duplo',
    'EP CD',
    'Mini CD',
  ];

  static const List<String> _vinylFormatOptions = [
    'LP',
    'EP',
    '7" Single',
    '10"',
    '12" Single',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _picker = ImagePicker();

  int? _selectedArtistId;
  String? _selectedFormatEdition;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _loadedInitialValues = false;

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;
    final artistsAsync = ref.watch(artistsProvider);
    final AsyncValue<AlbumDetailsViewData?> detailsAsync =
        widget.isEdit && widget.itemId != null
        ? ref.watch(
            albumDetailsProvider(
              AlbumDetailsKey(albumId: widget.itemId!, itemType: widget.itemType),
            ),
          )
        : const AsyncData<AlbumDetailsViewData?>(null);
    final formatOptions = _availableFormatOptions(widget.itemType);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar item' : 'Novo item'),
      ),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Apenas administradores podem criar ou editar itens.'),
              ),
            )
          : artistsAsync.when(
        
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar artistas: $error')),
        data: (artists) {
          if (artists.isEmpty) {
            return const Center(
              child: Text('Cria artistas primeiro para adicionares itens.'),
            );
          }

          return detailsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro ao carregar item: $error')),
            data: (details) {
              if (widget.isEdit && details != null && !_loadedInitialValues) {
                _titleController.text = details.album.title;
                _coverUrlController.text = details.album.coverUrl ?? '';
                _selectedArtistId = details.album.artistId;
                _selectedFormatEdition = details.album.formatEdition;
                _loadedInitialValues = true;
              }

              _selectedArtistId ??= artists.first.id;
              _selectedFormatEdition ??= formatOptions.first;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.isEdit ? 'Editar item' : 'Novo item',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.itemType == ItemType.cd
                        ? 'Preenche os dados do CD'
                        : 'Preenche os dados do vinil',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemType == ItemType.cd ? 'CD' : 'Vinil',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Título',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Indica um título';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _ArtistSelectorField(
                                    selectedArtist: artists.cast<Artist?>().firstWhere(
                                          (a) => a?.id == _selectedArtistId,
                                          orElse: () => null,
                                        ),
                                    onTap: () async {
                                      final selectedId = await _showArtistPicker(
                                        context,
                                        artists,
                                      );
                                      if (selectedId == null) return;
                                      if (!mounted) return;
                                      setState(() {
                                        _selectedArtistId = selectedId;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  tooltip: 'Novo artista',
                                  onPressed: () async {
                                    await context.push('/admin/artists/new');
                                    ref.invalidate(artistsProvider);
                                  },
                                  icon: const Icon(Icons.person_add_alt_1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedFormatEdition,
                              items: _mergeWithCurrentFormat(
                                options: formatOptions,
                                current: _selectedFormatEdition,
                              )
                                  .map(
                                    (format) => DropdownMenuItem<String>(
                                      value: format,
                                      child: Text(format),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedFormatEdition = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Formato / Edição',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Seleciona um formato';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _coverUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL da capa',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_coverUrlController.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Image.network(
                                      _coverUrlController.text.trim(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () async {
                                      final picked = await _picker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1600,
                                        imageQuality: 85,
                                      );
                                      if (picked == null) return;

                                      try {
                                        setState(() {
                                          _isUploading = true;
                                        });
                                        final bytes = await picked.readAsBytes();
                                        final extension = picked.name.contains('.')
                                            ? picked.name.split('.').last
                                            : 'jpg';

                                        final url = await ref
                                            .read(albumRepositoryProvider)
                                            .uploadCover(
                                              fileBytes: bytes,
                                              fileExtension: extension,
                                            );

                                        if (!mounted) return;
                                        setState(() {
                                          _coverUrlController.text = url;
                                        });
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Capa carregada com sucesso'),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erro ao carregar capa: $e'),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isUploading = false;
                                          });
                                        }
                                      }
                                    },
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file_outlined),
                              label: const Text('Upload capa'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) {
                                          return;
                                        }
                                        if (_selectedArtistId == null) {
                                          return;
                                        }

                                        try {
                                          setState(() {
                                            _isSaving = true;
                                          });

                                          final repo = ref.read(albumRepositoryProvider);
                                          if (widget.isEdit && widget.itemId != null) {
                                            await repo.updateItem(
                                              itemType: widget.itemType,
                                              itemId: widget.itemId!,
                                              title: _titleController.text.trim(),
                                              artistId: _selectedArtistId!,
                                              formatEdition: _selectedFormatEdition,
                                              coverUrl: _coverUrlController.text.trim(),
                                            );
                                          } else {
                                            await repo.createItem(
                                              itemType: widget.itemType,
                                              title: _titleController.text.trim(),
                                              artistId: _selectedArtistId!,
                                              formatEdition: _selectedFormatEdition,
                                              coverUrl: _coverUrlController.text.trim(),
                                            );
                                          }

                                          ref.invalidate(albumListItemsProvider);
                                          ref.invalidate(visibleAlbumsProvider);
                                          if (widget.itemId != null) {
                                            ref.invalidate(
                                              albumDetailsProvider(
                                                AlbumDetailsKey(
                                                  albumId: widget.itemId!,
                                                  itemType: widget.itemType,
                                                ),
                                              ),
                                            );
                                          }

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                widget.isEdit
                                                    ? 'Item atualizado com sucesso'
                                                    : 'Item criado com sucesso',
                                              ),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erro ao guardar item: $e')),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isSaving = false;
                                            });
                                          }
                                        }
                                      },
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(widget.isEdit ? 'Guardar' : 'Criar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<String> _availableFormatOptions(ItemType itemType) {
    return itemType == ItemType.cd ? _cdFormatOptions : _vinylFormatOptions;
  }

  List<String> _mergeWithCurrentFormat({
    required List<String> options,
    required String? current,
  }) {
    if (current == null || current.trim().isEmpty) return options;
    if (options.contains(current)) return options;
    return [...options, current];
  }

  Future<int?> _showArtistPicker(
    BuildContext context,
    List<Artist> artists,
  ) async {
    final queryController = TextEditingController();
    var query = '';

    final selectedArtistId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredArtists = artists.where((artist) {
              if (query.trim().isEmpty) return true;
              return artist.name.toLowerCase().contains(query.toLowerCase());
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
                      hintText: 'Pesquisar artista...',
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
                    child: filteredArtists.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sem artistas para esta pesquisa'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredArtists.length,
                          separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final artist = filteredArtists[index];
                              return ListTile(
                                title: Text(artist.name),
                                subtitle: artist.genreText == null ||
                                        artist.genreText!.trim().isEmpty
                                    ? null
                                    : Text(artist.genreText!),
                                onTap: () => Navigator.of(sheetContext).pop(artist.id),
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
    return selectedArtistId;
  }
}

class _ArtistSelectorField extends StatelessWidget {
  const _ArtistSelectorField({
    required this.selectedArtist,
    required this.onTap,
  });

  final Artist? selectedArtist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Artista',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          selectedArtist?.name ?? 'Selecionar artista',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
