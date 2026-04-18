import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/active_loan_details.dart';
import '../../../shared/models/active_loan_list_item.dart';
import '../../../shared/models/album_loan.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/repositories/loan_repository.dart';
import '../../albums/application/album_providers.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository();
});

final activeLoansProvider = FutureProvider<List<AlbumLoan>>((ref) {
  final repository = ref.watch(loanRepositoryProvider);
  return repository.listActiveLoans();
});

final activeLoanListItemsProvider = FutureProvider<List<ActiveLoanListItem>>((
  ref,
) {
  final repository = ref.watch(loanRepositoryProvider);
  return repository.listActiveLoanListItems();
});

final outsideShelfAlbumsProvider = FutureProvider<List<AlbumListItem>>((ref) {
  final repository = ref.watch(loanRepositoryProvider);
  return repository.listOutsideShelfAlbums();
});

final activeLoanForAlbumProvider = FutureProvider.family<AlbumLoan?, int>((
  ref,
  albumId,
) {
  final repository = ref.watch(loanRepositoryProvider);
  return repository.getActiveLoanForAlbum(albumId);
});

final activeLoanDetailsForAlbumProvider =
    FutureProvider.family<ActiveLoanDetails?, int>((ref, albumId) {
      final repository = ref.watch(loanRepositoryProvider);
      return repository.getActiveLoanDetailsForAlbum(albumId);
    });

final loanActionsProvider = Provider<LoanActions>((ref) {
  return LoanActions(ref);
});

class LoanActions {
  const LoanActions(this._ref);

  final Ref _ref;

  Future<void> borrowAlbum(int albumId) async {
    final repository = _ref.read(loanRepositoryProvider);
    await repository.borrowAlbum(albumId);
    _invalidateLoanState(albumId);
  }

  Future<void> returnAlbum(int albumId) async {
    final repository = _ref.read(loanRepositoryProvider);
    await repository.returnAlbum(albumId);
    _invalidateLoanState(albumId);
  }

  void _invalidateLoanState(int albumId) {
    _ref.invalidate(activeLoansProvider);
    _ref.invalidate(activeLoanListItemsProvider);
    _ref.invalidate(outsideShelfAlbumsProvider);
    _ref.invalidate(activeLoanForAlbumProvider(albumId));
    _ref.invalidate(activeLoanDetailsForAlbumProvider(albumId));
    _ref.invalidate(albumDetailsProvider(albumId));
    _ref.invalidate(albumListItemsProvider);
    _ref.invalidate(albumsProvider);
  }
}
