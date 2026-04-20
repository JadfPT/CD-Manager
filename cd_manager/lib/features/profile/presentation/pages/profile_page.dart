import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/models/album_list_item.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../../shared/models/item_type.dart';
import '../../application/profile_providers.dart';
import '../../application/profile_update_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _loadedProfileId;
  bool _isUploadingAvatar = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final statsAsync = ref.watch(profileLibraryStatsProvider);
    final recentItemsAsync = ref.watch(recentAddedItemsProvider);
    final updateState = ref.watch(profileUpdateControllerProvider);
    final authState = ref.watch(authProvider);

    final email = authState is AuthSuccess ? authState.user.email : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Random',
            onPressed: () => context.push('/random'),
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const _ProfilePageSkeleton(),
        error: (error, stackTrace) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          final profileId = profile?.id;
          if (_loadedProfileId != profileId) {
            _usernameController.text = profile?.username ?? '';
            _displayNameController.text = profile?.displayName ?? '';
            _avatarUrlController.text = profile?.avatarUrl ?? '';
            _loadedProfileId = profileId;
          }

          final avatarSource = _avatarUrlController.text.trim().isNotEmpty
              ? _avatarUrlController.text.trim()
              : profile?.avatarUrl;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSectionCard(
                title: 'Identidade',
                subtitle: 'Dados públicos da tua conta',
                child: Column(
                  children: [
                      _AvatarPreview(avatarUrl: avatarSource),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isUploadingAvatar
                            ? null
                            : () async {
                                final picked = await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1200,
                                  imageQuality: 85,
                                );

                                if (picked == null) return;

                                try {
                                  setState(() {
                                    _isUploadingAvatar = true;
                                  });

                                  final bytes = await picked.readAsBytes();
                                  final nameParts = picked.name.split('.');
                                  final extension = nameParts.length > 1
                                      ? nameParts.last
                                      : 'jpg';

                                  final url = await ref
                                      .read(profileActionsProvider)
                                      .uploadAvatar(
                                        fileBytes: bytes,
                                        fileExtension: extension,
                                      );

                                  _avatarUrlController.text = url;

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Avatar atualizado com sucesso'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao carregar avatar: $e'),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isUploadingAvatar = false;
                                    });
                                  }
                                }
                              },
                        icon: _isUploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_camera_outlined),
                        label: const Text('Carregar avatar'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile?.displayName?.trim().isNotEmpty == true
                            ? profile!.displayName!
                            : 'Sem nome de apresentação',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile?.username?.trim().isNotEmpty == true
                            ? '@${profile!.username!}'
                            : '@sem-username',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email ?? 'Email não disponível',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      _AdminBadge(isAdmin: profile?.isAdmin ?? false),
                    ],
                ),
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                title: 'Editar perfil',
                subtitle: 'Username, nome de apresentação e avatar',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'nome_utilizador',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Indica um username';
                            }
                            if (text.length < 3) {
                              return 'Mínimo de 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            hintText: 'Nome visível',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Indica um nome de apresentação';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: updateState.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  try {
                                    await ref
                                        .read(
                                          profileUpdateControllerProvider
                                              .notifier,
                                        )
                                        .save(
                                          username: _usernameController.text
                                              .trim(),
                                          displayName: _displayNameController
                                              .text
                                              .trim(),
                                          avatarUrl: _avatarUrlController.text
                                              .trim(),
                                        );

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Perfil atualizado com sucesso',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao atualizar perfil: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: updateState.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Guardar alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingSkeleton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 140, height: 16),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: SkeletonBox(height: 58, radius: 14)),
                              SizedBox(width: 8),
                              Expanded(child: SkeletonBox(height: 58, radius: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (error, _) => AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(profileLibraryStatsProvider),
                ),
                data: (stats) => _StatsGrid(stats: stats),
              ),
              const SizedBox(height: 12),
              recentItemsAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingSkeleton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 160, height: 16),
                          SizedBox(height: 10),
                          SkeletonBox(height: 58, radius: 14),
                          SizedBox(height: 8),
                          SkeletonBox(height: 58, radius: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (error, _) => AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(recentAddedItemsProvider),
                ),
                data: (items) => _RecentItemsCard(items: items),
              ),
              const SizedBox(height: 12),
              if (profile?.isAdmin ?? false) ...[
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/admin/wishlist'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Wishlist Admin'),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.tonalIcon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Definições'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ProfileLibraryStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'CDs', value: stats.cdCount.toString(), icon: Icons.album_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Vinis', value: stats.vinylCount.toString(), icon: Icons.album)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Favoritos', value: stats.favoriteArtistsCount.toString(), icon: Icons.star_outline)),
      ],
    );
  }
}

class _ProfilePageSkeleton extends StatelessWidget {
  const _ProfilePageSkeleton();

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonBox(width: 84, height: 84, radius: 999),
                  SizedBox(height: 12),
                  SkeletonBox(width: 170, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 130, height: 12),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 16),
                  SizedBox(height: 12),
                  SkeletonBox(height: 48, radius: 14),
                  SizedBox(height: 10),
                  SkeletonBox(height: 48, radius: 14),
                  SizedBox(height: 12),
                  SkeletonBox(height: 46, radius: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItemsCard extends StatelessWidget {
  const _RecentItemsCard({required this.items});

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimos adicionados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.coverUrl != null && item.coverUrl!.trim().isNotEmpty
                        ? Image.network(
                            item.coverUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.album, size: 20),
                          ),
                  ),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${item.artistName} • ${item.itemType == ItemType.cd ? 'CD' : 'Vinil'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 42,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundImage: hasUrl ? NetworkImage(avatarUrl!) : null,
      child: hasUrl
          ? null
          : Icon(
              Icons.person,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final background = isAdmin
        ? colors.primaryContainer.withValues(alpha: 0.8)
        : colors.surfaceContainerHighest;
    final foreground = isAdmin
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'Administrador' : 'Utilizador',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
