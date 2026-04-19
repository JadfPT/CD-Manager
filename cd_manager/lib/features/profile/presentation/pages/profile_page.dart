import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../auth/application/auth_providers.dart';
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

  String? _loadedProfileId;

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
    final updateState = ref.watch(profileUpdateControllerProvider);
    final authState = ref.watch(authProvider);

    final email = authState is AuthSuccess ? authState.user.email : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _AvatarPreview(avatarUrl: avatarSource),
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
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar perfil',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _avatarUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Avatar URL',
                            hintText: 'https://...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final uri = Uri.tryParse(text);
                            final isValid =
                                uri != null &&
                                (uri.scheme == 'http' ||
                                    uri.scheme == 'https') &&
                                uri.host.isNotEmpty;
                            if (!isValid) return 'URL de avatar inválida';
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
