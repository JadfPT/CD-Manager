import 'package:flutter/material.dart';
import '../../application/profile_providers.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_section_card.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    required this.avatarUrl,
    required this.displayName,
    required this.username,
    required this.email,
    required this.isAdmin,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
    super.key,
  });

  final String? avatarUrl;
  final String displayName;
  final String username;
  final String email;
  final bool isAdmin;
  final bool isUploadingAvatar;
  final Future<void> Function() onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Identidade',
      subtitle: 'Dados públicos da tua conta',
      child: Column(
        children: [
          _ClickableAvatar(
            avatarUrl: avatarUrl,
            isUploading: isUploadingAvatar,
            onTap: onAvatarTap,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            username,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          _AdminBadge(isAdmin: isAdmin),
        ],
      ),
    );
  }
}

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({required this.stats, super.key});

  final ProfileLibraryStats stats;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Resumo da biblioteca',
      subtitle: 'Visão rápida do teu estado atual',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _StatTile(
            label: 'CDs',
            value: stats.cdCount.toString(),
            icon: Icons.album_outlined,
          ),
          _StatTile(
            label: 'Vinis',
            value: stats.vinylCount.toString(),
            icon: Icons.album,
          ),
          _StatTile(
            label: 'Total coleção',
            value: stats.totalItemsCount.toString(),
            icon: Icons.library_music_outlined,
          ),
          _StatTile(
            label: 'Favoritos (itens)',
            value: stats.favoriteItemsCount.toString(),
            icon: Icons.favorite_outline,
          ),
          _StatTile(
            label: 'Favoritos (artistas)',
            value: stats.favoriteArtistsCount.toString(),
            icon: Icons.star_outline,
          ),
          _StatTile(
            label: 'Wishlist',
            value: stats.wishlistCount.toString(),
            icon: Icons.push_pin_outlined,
          ),
          _StatTile(
            label: 'Fora da prateleira',
            value: stats.offShelfCount.toString(),
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }
}

class _ClickableAvatar extends StatelessWidget {
  const _ClickableAvatar({
    required this.avatarUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String? avatarUrl;
  final bool isUploading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: isUploading ? null : () => onTap(),
      child: Stack(
        children: [
          AppNetworkImage(
            imageUrl: avatarUrl,
            width: 92,
            height: 92,
            borderRadius: BorderRadius.circular(999),
            placeholder: Container(
              color: colors.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.person,
                size: 38,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: isUploading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: colors.onPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final foreground = isAdmin ? colors.onPrimaryContainer : colors.onSurfaceVariant;

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
