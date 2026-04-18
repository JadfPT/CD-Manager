import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_album_note.dart';
import '../../../shared/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final albumNoteProvider = FutureProvider.family<UserAlbumNote?, int>((ref, albumId) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNoteForAlbum(albumId);
});

final noteActionsProvider = Provider<NoteActions>((ref) {
  return NoteActions(ref);
});

class NoteActions {
  const NoteActions(this._ref);

  final Ref _ref;

  Future<UserAlbumNote> save({required int albumId, required String note}) async {
    final repository = _ref.read(noteRepositoryProvider);
    final result = await repository.upsertNote(albumId: albumId, note: note);
    _ref.invalidate(albumNoteProvider(albumId));
    return result;
  }

  Future<void> delete(int albumId) async {
    final repository = _ref.read(noteRepositoryProvider);
    await repository.deleteNote(albumId);
    _ref.invalidate(albumNoteProvider(albumId));
  }
}
