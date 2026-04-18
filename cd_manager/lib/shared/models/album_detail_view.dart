import 'album.dart';
import 'album_loan.dart';
import 'artist.dart';
import 'user_album_note.dart';

class AlbumDetailsViewData {
  const AlbumDetailsViewData({
    required this.album,
    required this.artist,
    required this.isFavorite,
    required this.userNote,
    required this.activeLoan,
    required this.currentUserIsAdmin,
  });

  final Album album;
  final Artist artist;
  final bool isFavorite;
  final UserAlbumNote? userNote;
  final AlbumLoan? activeLoan;
  final bool currentUserIsAdmin;
}
