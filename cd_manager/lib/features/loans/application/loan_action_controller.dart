import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'loan_providers.dart';

final loanActionControllerProvider =
    StateNotifierProvider.family<LoanActionController, AsyncValue<void>, LoanItemKey>(
      (ref, key) => LoanActionController(ref, key),
    );

class LoanActionController extends StateNotifier<AsyncValue<void>> {
  LoanActionController(this._ref, this._key) : super(const AsyncData(null));

  final Ref _ref;
  final LoanItemKey _key;

  Future<void> borrow() async {
    state = const AsyncLoading();

    try {
      debugPrint('[LoanActionController] borrow albumId=${_key.albumId} type=${_key.itemType.value}');
      await _ref.read(loanActionsProvider).borrowAlbum(_key.albumId, _key.itemType);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> returnAlbum() async {
    state = const AsyncLoading();

    try {
      debugPrint('[LoanActionController] returnAlbum albumId=${_key.albumId} type=${_key.itemType.value}');
      await _ref.read(loanActionsProvider).returnAlbum(_key.albumId, _key.itemType);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
