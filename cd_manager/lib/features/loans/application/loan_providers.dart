import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/active_loan_details.dart';
import '../../../shared/models/active_loan_list_item.dart';
import '../../../shared/models/album_loan.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/item_type.dart';
import '../../../shared/repositories/loan_repository.dart';
import '../../albums/application/album_providers.dart';

class LoanItemKey {
  const LoanItemKey({
    required this.albumId,
    required this.itemType,
  });

  final int albumId;
  final ItemType itemType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoanItemKey &&
        other.albumId == albumId &&
        other.itemType == itemType;
  }

  @override
  int get hashCode => Object.hash(albumId, itemType);
}

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

final activeLoanForAlbumProvider =
    FutureProvider.family<AlbumLoan?, LoanItemKey>((ref, key) {
  final repository = ref.watch(loanRepositoryProvider);
  return repository.getActiveLoanForAlbum(
    key.albumId,
    itemType: key.itemType,
  );
});

final activeLoanDetailsForAlbumProvider =
    FutureProvider.family<ActiveLoanDetails?, LoanItemKey>((ref, key) {
      final repository = ref.watch(loanRepositoryProvider);
      return repository.getActiveLoanDetailsForAlbum(
        key.albumId,
        itemType: key.itemType,
      );
    });

final loanActionsProvider = Provider<LoanActions>((ref) {
  return LoanActions(ref);
});

class LoanActions {
  const LoanActions(this._ref);

  final Ref _ref;

  Future<void> borrowAlbum(int albumId, ItemType itemType) async {
    final repository = _ref.read(loanRepositoryProvider);
    await repository.borrowAlbum(albumId, itemType: itemType);
    _invalidateLoanState(albumId, itemType);
  }

  Future<void> returnAlbum(int albumId, ItemType itemType) async {
    final repository = _ref.read(loanRepositoryProvider);
    await repository.returnAlbum(albumId, itemType: itemType);
    _invalidateLoanState(albumId, itemType);
  }

  void _invalidateLoanState(int albumId, ItemType itemType) {
    _ref.invalidate(activeLoansProvider);
    _ref.invalidate(activeLoanListItemsProvider);
    _ref.invalidate(outsideShelfAlbumsProvider);
    _ref.invalidate(activeLoanForAlbumProvider(
      LoanItemKey(albumId: albumId, itemType: itemType),
    ));
    _ref.invalidate(activeLoanDetailsForAlbumProvider(
      LoanItemKey(albumId: albumId, itemType: itemType),
    ));
    _ref.invalidate(
      albumDetailsProvider(AlbumDetailsKey(albumId: albumId, itemType: itemType)),
    );
    _ref.invalidate(albumListItemsProvider);
    _ref.invalidate(albumsProvider);
  }
}
