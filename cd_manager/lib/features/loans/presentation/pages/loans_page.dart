import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../albums/presentation/widgets/album_cover.dart';
import '../../application/loan_providers.dart';

class LoansPage extends ConsumerWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(activeLoanListItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fora da Prateleira')),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(activeLoanListItemsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhum CD fora da prateleira',
              subtitle: 'Quando um CD for marcado, vai aparecer aqui.',
              icon: Icons.inventory_2_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeLoanListItemsProvider);
              await ref.read(activeLoanListItemsProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/albums/${item.albumId}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AlbumCover(
                            coverUrl: item.coverUrl,
                            title: item.title,
                            size: 72,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.artistName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  label: 'ID',
                                  value: '#${item.albumId}',
                                ),
                                const SizedBox(height: 4),
                                _InfoRow(
                                  label: 'Quem marcou',
                                  value: item.borrowerLabel,
                                ),
                                const SizedBox(height: 4),
                                _InfoRow(
                                  label: 'Quando marcou',
                                  value: _formatDate(item.borrowedAt),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
