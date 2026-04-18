import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/album.dart';
import '../models/album_detail_view.dart';
import '../models/album_list_item.dart';
import '../models/album_loan.dart';
import '../models/artist.dart';
import '../models/user_album_note.dart';

class AlbumRepository {
  AlbumRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<List<Album>> listAlbums({bool? onShelf}) async {
    try {
      var query = _client
          .from('albums')
          .select('id, title, artist_id, on_shelf, cover_url, created_at');

      if (onShelf != null) {
        query = query.eq('on_shelf', onShelf);
      }

      final data = await query.order('id', ascending: true);
      return data.map((row) => Album.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar álbuns: $e');
    }
  }

  Future<List<AlbumListItem>> listAlbumListItems({
    String? searchText,
    bool? onShelf,
  }) async {
    try {
      var query = _client.from('albums').select(
            'id, title, artist_id, on_shelf, cover_url, created_at, '
            'artists!inner(id, name, genre_text, created_at)',
          );

      if (onShelf != null) {
        query = query.eq('on_shelf', onShelf);
      }

      final data = await query.order('id', ascending: true);

      var items = data.map((row) {
        final artistMap = row['artists'] as Map<String, dynamic>;
        return AlbumListItem(
          albumId: _asInt(row['id']),
          title: row['title'] as String,
          artistId: _asInt(row['artist_id']),
          artistName: artistMap['name'] as String,
          artistGenreText: artistMap['genre_text'] as String?,
          onShelf: row['on_shelf'] as bool,
          coverUrl: row['cover_url'] as String?,
          createdAt: _asDateTime(row['created_at']),
        );
      }).toList();

      final normalizedSearch = searchText?.trim().toLowerCase();
      if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
        items = items
            .where(
              (item) =>
                  item.title.toLowerCase().contains(normalizedSearch) ||
                  item.artistName.toLowerCase().contains(normalizedSearch),
            )
            .toList();
      }

      return items;
    } catch (e) {
      throw AppException(message: 'Falha ao obter lista de álbuns: $e');
    }
  }

  Future<AlbumDetailsViewData> getAlbumDetails(int albumId) async {
    final userId = _requireUserId();

    try {
      final albumRow = await _client
          .from('albums')
          .select(
            'id, title, artist_id, on_shelf, cover_url, created_at, '
            'artists!inner(id, name, genre_text, created_at)',
          )
          .eq('id', albumId)
          .single();

      final album = Album.fromMap(albumRow);
      final artist = Artist.fromMap(albumRow['artists'] as Map<String, dynamic>);

      final favoriteRow = await _client
          .from('user_favorite_albums')
          .select('album_id')
          .eq('user_id', userId)
          .eq('album_id', albumId)
          .maybeSingle();

      final noteRow = await _client
          .from('user_album_notes')
          .select('user_id, album_id, note, updated_at')
          .eq('user_id', userId)
          .eq('album_id', albumId)
          .maybeSingle();

      final loanRow = await _client
          .from('album_loans')
          .select('id, album_id, borrowed_by_user_id, borrowed_at, returned_at')
          .eq('album_id', albumId)
          .isFilter('returned_at', null)
          .order('borrowed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      bool currentUserIsAdmin = false;
      try {
        final isAdminResult = await _client.rpc('current_user_is_admin');
        if (isAdminResult is bool) {
          currentUserIsAdmin = isAdminResult;
        }
      } catch (_) {
        currentUserIsAdmin = false;
      }

      return AlbumDetailsViewData(
        album: album,
        artist: artist,
        isFavorite: favoriteRow != null,
        userNote: noteRow == null ? null : UserAlbumNote.fromMap(noteRow),
        activeLoan: loanRow == null ? null : AlbumLoan.fromMap(loanRow),
        currentUserIsAdmin: currentUserIsAdmin,
      );
    } catch (e) {
      throw AppException(message: 'Falha ao obter detalhe do álbum: $e');
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }
}
