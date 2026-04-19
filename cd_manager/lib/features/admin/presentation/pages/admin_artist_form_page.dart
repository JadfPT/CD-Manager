import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/artists/application/artist_providers.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../shared/models/artist.dart';

class AdminArtistFormPage extends ConsumerStatefulWidget {
  const AdminArtistFormPage.create({super.key})
      : artistId = null,
        isEdit = false;

  const AdminArtistFormPage.edit({
    required this.artistId,
    super.key,
  }) : isEdit = true;

  final int? artistId;
  final bool isEdit;

  @override
  ConsumerState<AdminArtistFormPage> createState() => _AdminArtistFormPageState();
}

class _AdminArtistFormPageState extends ConsumerState<AdminArtistFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSaving = false;
  bool _isUploading = false;
  bool _loadedInitialValues = false;

  @override
  void dispose() {
    _nameController.dispose();
    _genreController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;
    final AsyncValue<Artist?> artistAsync =
        widget.isEdit && widget.artistId != null
            ? ref.watch(artistByIdProvider(widget.artistId!))
            : const AsyncData<Artist?>(null);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Editar artista' : 'Novo artista')),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Apenas administradores podem criar ou editar artistas.'),
              ),
            )
          : artistAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erro ao carregar artista: $error'),
                ),
              ),
              data: (artist) {
                if (widget.isEdit && artist == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Artista não encontrado.'),
                    ),
                  );
                }

                if (widget.isEdit && artist != null && !_loadedInitialValues) {
                  _nameController.text = artist.name;
                  _genreController.text = artist.genreText ?? '';
                  _imageUrlController.text = artist.imageUrl ?? '';
                  _loadedInitialValues = true;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dados do artista',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return 'Indica o nome do artista';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _genreController,
                                decoration: const InputDecoration(
                                  labelText: 'Género (opcional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _imageUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'URL da imagem (opcional)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 10),
                              if (_imageUrlController.text.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 96,
                                        height: 96,
                                        child: Image.network(
                                          _imageUrlController.text.trim(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child:
                                                const Icon(Icons.image_not_supported),
                                          ),
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
                                              .read(artistRepositoryProvider)
                                              .uploadArtistImage(
                                                fileBytes: bytes,
                                                fileExtension: extension,
                                              );

                                          if (!mounted) return;
                                          setState(() {
                                            _imageUrlController.text = url;
                                          });
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Imagem do artista carregada com sucesso',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Erro ao carregar imagem do artista: $e',
                                              ),
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
                                label: const Text('Upload imagem'),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isSaving || _isUploading
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) {
                                            return;
                                          }

                                          try {
                                            setState(() {
                                              _isSaving = true;
                                            });

                                            final repo = ref.read(artistRepositoryProvider);
                                            if (widget.isEdit && widget.artistId != null) {
                                              await repo.updateArtist(
                                                artistId: widget.artistId!,
                                                name: _nameController.text.trim(),
                                                genreText: _genreController.text.trim(),
                                                imageUrl: _imageUrlController.text.trim(),
                                              );
                                            } else {
                                              await repo.createArtist(
                                                name: _nameController.text.trim(),
                                                genreText: _genreController.text.trim(),
                                                imageUrl: _imageUrlController.text.trim(),
                                              );
                                            }

                                            ref.invalidate(artistsProvider);
                                            ref.invalidate(artistDetailsProvider);
                                            if (widget.artistId != null) {
                                              ref.invalidate(artistByIdProvider(widget.artistId!));
                                            }

                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  widget.isEdit
                                                      ? 'Artista atualizado com sucesso'
                                                      : 'Artista criado com sucesso',
                                                ),
                                              ),
                                            );
                                            Navigator.of(context).pop();
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  widget.isEdit
                                                      ? 'Erro ao editar artista: $e'
                                                      : 'Erro ao criar artista: $e',
                                                ),
                                              ),
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
                                  label: Text(widget.isEdit ? 'Guardar' : 'Criar artista'),
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
            ),
    );
  }
}
