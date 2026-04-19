import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'note_providers.dart';

final noteEditorControllerProvider =
    StateNotifierProvider.family<NoteEditorController, AsyncValue<void>, int>(
  (ref, albumId) => NoteEditorController(ref, albumId),
);

class NoteEditorController extends StateNotifier<AsyncValue<void>> {
  NoteEditorController(this._ref, this._albumId) : super(const AsyncData(null));

  final Ref _ref;
  final int _albumId;

  Future<void> save(String note) async {
    state = const AsyncLoading();

    try {
      final actions = _ref.read(noteActionsProvider);
      await actions.save(albumId: _albumId, note: note);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete() async {
    state = const AsyncLoading();

    try {
      final actions = _ref.read(noteActionsProvider);
      await actions.delete(_albumId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final itemNoteEditorControllerProvider =
    StateNotifierProvider.family<ItemNoteEditorController, AsyncValue<void>, NoteItemKey>(
  (ref, key) => ItemNoteEditorController(ref, key),
);

class ItemNoteEditorController extends StateNotifier<AsyncValue<void>> {
  ItemNoteEditorController(this._ref, this._key) : super(const AsyncData(null));

  final Ref _ref;
  final NoteItemKey _key;

  Future<void> save(String note) async {
    state = const AsyncLoading();

    try {
      final actions = _ref.read(noteActionsProvider);
      await actions.save(
        albumId: _key.itemId,
        note: note,
        itemType: _key.itemType,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete() async {
    state = const AsyncLoading();

    try {
      final actions = _ref.read(noteActionsProvider);
      await actions.delete(_key.itemId, itemType: _key.itemType);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
