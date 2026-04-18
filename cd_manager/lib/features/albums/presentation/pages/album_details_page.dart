import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/models/album_loan.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../favorites/application/favorite_providers.dart';
import '../../../favorites/application/favorite_toggle_controller.dart';
import '../../../loans/application/loan_action_controller.dart';
import '../../../loans/application/loan_providers.dart';
import '../../../notes/application/note_editor_controller.dart';
import '../../../notes/application/note_providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/album_providers.dart';
import '../widgets/album_header_card.dart';
import '../widgets/album_meta_section.dart';
import '../widgets/favorite_button.dart';
import '../widgets/note_editor_card.dart';

class AlbumDetailsPage extends ConsumerWidget {
  const AlbumDetailsPage({required this.albumId, super.key});

  final int albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(albumDetailsProvider(albumId));
    final favoriteAsync = ref.watch(isFavoriteAlbumProvider(albumId));
    final noteAsync = ref.watch(albumNoteProvider(albumId));
    final profileAsync = ref.watch(currentProfileProvider);
    final activeLoanDetailsAsync = ref.watch(
      activeLoanDetailsForAlbumProvider(albumId),
    );

    final favoriteActionState = ref.watch(
      favoriteToggleControllerProvider(albumId),
    );
    final noteActionState = ref.watch(noteEditorControllerProvider(albumId));
    final loanActionState = ref.watch(loanActionControllerProvider(albumId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do CD')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(albumDetailsProvider(albumId)),
        ),
        data: (details) {
          if (details.album.id != albumId) {
            return const AppEmptyState(
              title: 'CD não encontrado',
              subtitle: 'Este álbum pode ter sido removido.',
              icon: Icons.album_outlined,
            );
          }

          final isFavorite = favoriteAsync.maybeWhen(
            data: (value) => value,
            orElse: () => details.isFavorite,
          );

          final currentNote = noteAsync.maybeWhen(
            data: (note) => note?.note,
            orElse: () => details.userNote?.note,
          );

          final profile = profileAsync.valueOrNull;
          final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
          final isAdmin = profile?.isAdmin ?? false;

          final activeLoanDetails = activeLoanDetailsAsync.valueOrNull;
          final activeLoan = activeLoanDetails?.loan ?? details.activeLoan;
          final borrowerLabel =
              activeLoanDetails?.borrowerLabel ?? activeLoan?.borrowedByUserId;
          final canReturn =
              activeLoan != null &&
              currentUserId != null &&
              (isAdmin || currentUserId == activeLoan.borrowedByUserId);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(albumDetailsProvider(albumId));
              ref.invalidate(isFavoriteAlbumProvider(albumId));
              ref.invalidate(albumNoteProvider(albumId));
              ref.invalidate(activeLoanDetailsForAlbumProvider(albumId));
              await ref.read(albumDetailsProvider(albumId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AlbumHeaderCard(details: details),
                const SizedBox(height: 12),
                AlbumMetaSection(details: details),
                const SizedBox(height: 12),
                _LoanSection(
                  onShelf: details.album.onShelf,
                  activeLoan: activeLoan,
                  borrowerLabel: borrowerLabel,
                  canReturn: canReturn,
                  isLoadingAction: loanActionState.isLoading,
                  isLoadingLoanData: activeLoanDetailsAsync.isLoading,
                  onBorrow: () async {
                    try {
                      await ref
                          .read(loanActionControllerProvider(albumId).notifier)
                          .borrow();

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CD marcado como fora da prateleira'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao requisitar CD: $e')),
                      );
                    }
                  },
                  onReturn: () async {
                    try {
                      await ref
                          .read(loanActionControllerProvider(albumId).notifier)
                          .returnAlbum();

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CD devolvido com sucesso'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao devolver CD: $e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                FavoriteButton(
                  isFavorite: isFavorite,
                  isLoading: favoriteActionState.isLoading,
                  onPressed: () async {
                    try {
                      await ref
                          .read(
                            favoriteToggleControllerProvider(albumId).notifier,
                          )
                          .toggle(isFavorite: isFavorite);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? 'Removido dos favoritos'
                                : 'Adicionado aos favoritos',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao atualizar favorito: $e'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                NoteEditorCard(
                  initialNote: currentNote,
                  isBusy: noteActionState.isLoading,
                  onSave: (note) async {
                    try {
                      await ref
                          .read(noteEditorControllerProvider(albumId).notifier)
                          .save(note);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nota guardada com sucesso'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao guardar nota: $e')),
                      );
                    }
                  },
                  onDelete: () async {
                    try {
                      await ref
                          .read(noteEditorControllerProvider(albumId).notifier)
                          .delete();

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nota apagada com sucesso'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao apagar nota: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoanSection extends StatelessWidget {
  const _LoanSection({
    required this.onShelf,
    required this.activeLoan,
    required this.borrowerLabel,
    required this.canReturn,
    required this.isLoadingAction,
    required this.isLoadingLoanData,
    required this.onBorrow,
    required this.onReturn,
  });

  final bool onShelf;
  final AlbumLoan? activeLoan;
  final String? borrowerLabel;
  final bool canReturn;
  final bool isLoadingAction;
  final bool isLoadingLoanData;
  final Future<void> Function() onBorrow;
  final Future<void> Function() onReturn;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de requisição',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (onShelf) ...[
              Text(
                'Este CD está na prateleira.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isLoadingAction
                    ? null
                    : () async {
                        await onBorrow();
                      },
                icon: isLoadingAction
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.call_made),
                label: const Text('Marcar como fora da prateleira'),
              ),
            ] else ...[
              if (isLoadingLoanData && activeLoan == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (activeLoan != null) ...[
                _InfoRow(
                  label: 'Quem marcou',
                  value: borrowerLabel ?? 'Desconhecido',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Quando marcou',
                  value: _formatDate(activeLoan!.borrowedAt),
                ),
              ] else
                Text(
                  'CD fora da prateleira, sem detalhe de loan ativo disponível.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              if (canReturn)
                FilledButton.icon(
                  onPressed: isLoadingAction
                      ? null
                      : () async {
                          await onReturn();
                        },
                  icon: isLoadingAction
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_returned),
                  label: const Text('Devolver'),
                )
              else
                Text(
                  'Só o utilizador que marcou ou um admin pode devolver este CD.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
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
        style: Theme.of(context).textTheme.bodyMedium,
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
