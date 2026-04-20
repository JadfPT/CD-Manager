import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
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
      AppLogger.info(
        'borrow start albumId=${_key.albumId} type=${_key.itemType.value}',
        category: 'loans',
      );
      await _ref.read(loanActionsProvider).borrowAlbum(_key.albumId, _key.itemType);
      state = const AsyncData(null);
      AppLogger.info(
        'borrow success albumId=${_key.albumId} type=${_key.itemType.value}',
        category: 'loans',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'borrow failed albumId=${_key.albumId} type=${_key.itemType.value}',
        category: 'loans',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> returnAlbum() async {
    state = const AsyncLoading();

    try {
      AppLogger.info(
        'return start albumId=${_key.albumId} type=${_key.itemType.value}',
        category: 'loans',
      );
      await _ref.read(loanActionsProvider).returnAlbum(_key.albumId, _key.itemType);
      state = const AsyncData(null);
      AppLogger.info(
        'return success albumId=${_key.albumId} type=${_key.itemType.value}',
        category: 'loans',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'return failed albumId=${_key.albumId} type=${_key.itemType.value}',
        category: 'loans',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
