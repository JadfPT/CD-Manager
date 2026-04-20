import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/application/ui_action_executor.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/profile_providers.dart';
import '../../application/profile_update_controller.dart';
import '../widgets/profile_edit_section.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/recent_items_section.dart';

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

  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (picked == null) return;
    if (!mounted) return;

    try {
      setState(() {
        _isUploadingAvatar = true;
      });

      final bytes = await picked.readAsBytes();
      final nameParts = picked.name.split('.');
      final extension = nameParts.length > 1 ? nameParts.last : 'jpg';
      if (!mounted) return;

      String? uploadedUrl;
      final success = await UiActionExecutor.run(
        context,
        actionName: 'profile_upload_avatar',
        logCategory: 'profile.ui',
        action: () async {
          uploadedUrl = await ref
              .read(profileUpdateControllerProvider.notifier)
              .uploadAvatar(
                fileBytes: bytes,
                fileExtension: extension,
              );
        },
        successMessage: 'Avatar atualizado com sucesso.',
        errorMessage: 'Não foi possível carregar avatar.',
      );

      if (!success || uploadedUrl == null) return;

      if (!mounted) return;
      setState(() {
        _avatarUrlController.text = uploadedUrl!;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.info(context, 'Revê os campos destacados antes de guardar.');
      return;
    }

    await UiActionExecutor.run(
      context,
      actionName: 'profile_save',
      logCategory: 'profile.ui',
      action: () => ref.read(profileUpdateControllerProvider.notifier).save(
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim(),
          ),
      successMessage: 'Perfil atualizado com sucesso.',
      errorMessage: 'Não foi possível atualizar perfil.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final overviewAsync = ref.watch(profileOverviewProvider);
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
              ProfileHeaderCard(
                avatarUrl: avatarSource,
                displayName: profile?.displayName?.trim().isNotEmpty == true
                    ? profile!.displayName!
                    : 'Sem nome de apresentação',
                username: profile?.username?.trim().isNotEmpty == true
                    ? '@${profile!.username!}'
                    : '@sem-username',
                email: email ?? 'Email não disponível',
                isAdmin: profile?.isAdmin ?? false,
                isUploadingAvatar: _isUploadingAvatar,
                onAvatarTap: _pickAvatar,
              ),
              const SizedBox(height: 12),
              ProfileEditSection(
                formKey: _formKey,
                usernameController: _usernameController,
                displayNameController: _displayNameController,
                isSaving: updateState.isLoading,
                onSave: _saveProfile,
              ),
              const SizedBox(height: 12),
              overviewAsync.when(
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
                  onRetry: () => ref.invalidate(profileOverviewProvider),
                ),
                data: (overview) => ProfileStatsGrid(stats: overview.stats),
              ),
              const SizedBox(height: 12),
              overviewAsync.when(
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
                  onRetry: () => ref.invalidate(profileOverviewProvider),
                ),
                data: (overview) => RecentItemsSection(items: overview.recentItems),
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
