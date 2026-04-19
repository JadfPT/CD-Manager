import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/artists/application/artist_providers.dart';
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
                        isApproving: _loadingKeys.contains('approve-${item.id}'),
                        isRejecting: _loadingKeys.contains('reject-${item.id}'),
                        isConverting: _loadingKeys.contains('convert-${item.id}'),
                        onApprove: () => _runAction(
                          key: 'approve-${item.id}',
                          action: () async {
                            await ref.read(favoriteActionsProvider).updateWishlistStatus(
                                  item: item,
                                  status: WishlistStatus.approved,
                                );
                          },
                          successMessage: 'Pedido aprovado',
                        ),
                        onReject: () => _runAction(
                          key: 'reject-${item.id}',
                          action: () async {
                            await ref.read(favoriteActionsProvider).updateWishlistStatus(
                                  item: item,
                                  status: WishlistStatus.rejected,
                                );
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
                                    itemType: item.itemType,
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

    int? selectedArtistId;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolher artista para conversão'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fallbackName != null && fallbackName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Pedido com artista livre: $fallbackName'),
                    ),
                  DropdownButtonFormField<int>(
                    initialValue: selectedArtistId,
                    decoration: const InputDecoration(
                      labelText: 'Artista',
                      border: OutlineInputBorder(),
                    ),
                    items: artists
                        .map(
                          (artist) => DropdownMenuItem<int>(
                            value: artist.id,
                            child: Text(artist.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedArtistId = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selectedArtistId == null
                  ? null
                  : () => Navigator.of(context).pop(selectedArtistId),
              child: const Text('Converter'),
            ),
          ],
        );
      },
    );
  }
}

class _AdminWishlistCard extends StatelessWidget {
  const _AdminWishlistCard({
    required this.item,
    required this.isApproving,
    required this.isRejecting,
    required this.isConverting,
    required this.onApprove,
    required this.onReject,
    required this.onConvert,
  });

  final WishlistItem item;
  final bool isApproving;
  final bool isRejecting;
  final bool isConverting;
  final Future<void> Function() onApprove;
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
                  onPressed: isApproving || isRejecting || isConverting
                      ? null
                      : () async => onApprove(),
                  child: isApproving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aprovar'),
                ),
                OutlinedButton(
                  onPressed: isApproving || isRejecting || isConverting
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
                  onPressed: isApproving || isRejecting || isConverting
                      ? null
                      : () async => onConvert(),
                  child: isConverting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Adicionar à coleção'),
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
