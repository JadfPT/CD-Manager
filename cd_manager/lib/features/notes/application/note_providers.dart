import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/item_type.dart';
import '../../../shared/models/user_album_note.dart';
import '../../../shared/repositories/note_repository.dart';

class NoteItemKey {
  const NoteItemKey({
    required this.itemId,
    required this.itemType,
  });

  final int itemId;
  final ItemType itemType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteItemKey &&
        other.itemId == itemId &&
        other.itemType == itemType;
  }

  @override
  int get hashCode => Object.hash(itemId, itemType);
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final albumNoteProvider = FutureProvider.family<UserAlbumNote?, int>((ref, albumId) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNoteForAlbum(albumId);
});

final itemNoteProvider = FutureProvider.family<UserAlbumNote?, NoteItemKey>((ref, key) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNoteForAlbum(
    key.itemId,
    itemType: key.itemType,
  );
});

final noteActionsProvider = Provider<NoteActions>((ref) {
  return NoteActions(ref);
});

class NoteActions {
  const NoteActions(this._ref);

  final Ref _ref;

  Future<UserAlbumNote> save({
    required int albumId,
    required String note,
    ItemType itemType = ItemType.cd,
  }) async {
    final repository = _ref.read(noteRepositoryProvider);
    final result = await repository.upsertNote(
      albumId: albumId,
      note: note,
      itemType: itemType,
    );
    _ref.invalidate(albumNoteProvider(albumId));
    _ref.invalidate(itemNoteProvider(NoteItemKey(itemId: albumId, itemType: itemType)));
    return result;
  }

  Future<void> delete(int albumId, {ItemType itemType = ItemType.cd}) async {
    final repository = _ref.read(noteRepositoryProvider);
    await repository.deleteNote(albumId, itemType: itemType);
    _ref.invalidate(albumNoteProvider(albumId));
    _ref.invalidate(itemNoteProvider(NoteItemKey(itemId: albumId, itemType: itemType)));
  }
}
