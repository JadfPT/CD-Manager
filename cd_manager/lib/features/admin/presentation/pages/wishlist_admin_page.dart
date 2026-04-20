import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/artists/application/artist_providers.dart';
import '../../../../features/albums/application/album_providers.dart';
import '../../../../features/albums/application/album_view_providers.dart';
import '../../../../features/favorites/application/favorite_providers.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../shared/models/artist.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/models/wishlist_item.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';

class WishlistAdminPage extends ConsumerStatefulWidget {
  const WishlistAdminPage({super.key});

  @override
  ConsumerState<WishlistAdminPage> createState() => _WishlistAdminPageState();
}

class _WishlistAdminPageState extends ConsumerState<WishlistAdminPage> {
  final Set<String> _loadingKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;
    final wishlistAsync = ref.watch(adminWishlistProvider);
    final artists = ref.watch(artistsProvider).valueOrNull ?? const <Artist>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist Admin')),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Apenas administradores podem aceder a esta página.'),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminWishlistProvider);
                await ref.read(adminWishlistProvider.future);
              },
              child: wishlistAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(adminWishlistProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const AppEmptyState(
                      title: 'Sem pedidos na wishlist',
                      subtitle: 'Não existem itens pendentes para gestão.',
                      icon: Icons.inventory_2_outlined,
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _AdminWishlistCard(
                        item: item,
                        isRejecting: _loadingKeys.contains('reject-${item.id}'),
                        isConverting: _loadingKeys.contains('convert-${item.id}'),
                        onReject: () => _runAction(
                          key: 'reject-${item.id}',
                          action: () async {
                            await ref.read(favoriteActionsProvider).deleteWishlistItemAsAdmin(item);
                          },
                          successMessage: 'Pedido rejeitado',
                        ),
                        onConvert: () async {
                          final artistId = await _resolveArtistIdForConversion(
                            context: context,
                            item: item,
                            artists: artists,
                          );
                          if (artistId == null) return;

                          await _runAction(
                            key: 'convert-${item.id}',
                            action: () async {
                              await ref.read(favoriteActionsProvider).convertWishlistToCollection(
                                item: item,
                                artistId: artistId,
                              );
                            },
                            successMessage: 'Item convertido para coleção',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Future<void> _runAction({
    required String key,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_loadingKeys.contains(key)) return;

    setState(() {
      _loadingKeys.add(key);
    });

    try {
      await action();
      ref.invalidate(adminWishlistProvider);
      ref.invalidate(wishlistProvider);
      ref.invalidate(albumListItemsProvider);
      ref.invalidate(albumsProvider);
      ref.invalidate(visibleAlbumsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingKeys.remove(key);
        });
      }
    }
  }

  Future<int?> _resolveArtistIdForConversion({
    required BuildContext context,
    required WishlistItem item,
    required List<Artist> artists,
  }) async {
    if (item.artistId != null) {
      return item.artistId;
    }

    final fallbackName = item.artistName?.trim();

    if (fallbackName != null && fallbackName.isNotEmpty) {
      final matches = artists
          .where((artist) => artist.name.toLowerCase() == fallbackName.toLowerCase())
          .toList();
      if (matches.length == 1) {
        return matches.first.id;
      }
    }

    return _showArtistPicker(
      context: context,
      artists: artists,
      fallbackName: fallbackName,
    );
  }

  Future<int?> _showArtistPicker({
    required BuildContext context,
    required List<Artist> artists,
    String? fallbackName,
  }) async {
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
                  if (fallbackName != null && fallbackName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Pedido com artista livre: $fallbackName'),
                    ),
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
                            separatorBuilder: (context, index) => const Divider(height: 1),
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

class _AdminWishlistCard extends StatelessWidget {
  const _AdminWishlistCard({
    required this.item,
    required this.isRejecting,
    required this.isConverting,
    required this.onReject,
    required this.onConvert,
  });

  final WishlistItem item;
  final bool isRejecting;
  final bool isConverting;
  final Future<void> Function() onReject;
  final Future<void> Function() onConvert;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      WishlistStatus.pending => Colors.grey,
      WishlistStatus.approved => Colors.blue,
      WishlistStatus.converted => Colors.green,
      WishlistStatus.rejected => Colors.red,
    };

    final typeLabel = item.itemType == ItemType.cd ? 'CD' : 'VINYL';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.artistId != null
                  ? '${item.displayArtistName} (#${item.artistId})'
                  : item.displayArtistName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Pedido por: ${item.requesterLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(label: typeLabel, color: Colors.purple),
                _Badge(label: item.status.name, color: statusColor),
                _Badge(label: 'Wishlist', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: isRejecting || isConverting
                      ? null
                      : () async => onReject(),
                  child: isRejecting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Rejeitar'),
                ),
                FilledButton.tonal(
                  onPressed: isRejecting || isConverting
                      ? null
                      : () async => onConvert(),
                  child: isConverting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Converter para coleção'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
