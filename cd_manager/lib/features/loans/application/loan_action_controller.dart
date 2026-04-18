import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'loan_providers.dart';

final loanActionControllerProvider =
    StateNotifierProvider.family<LoanActionController, AsyncValue<void>, int>(
      (ref, albumId) => LoanActionController(ref, albumId),
    );

class LoanActionController extends StateNotifier<AsyncValue<void>> {
  LoanActionController(this._ref, this._albumId) : super(const AsyncData(null));

  final Ref _ref;
  final int _albumId;

  Future<void> borrow() async {
    state = const AsyncLoading();

    try {
      await _ref.read(loanActionsProvider).borrowAlbum(_albumId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> returnAlbum() async {
    state = const AsyncLoading();

    try {
      await _ref.read(loanActionsProvider).returnAlbum(_albumId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
