import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/album_list_item.dart';
import '../models/artist.dart';
import '../models/item_type.dart';

class ArtistRepository {
  ArtistRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<Artist>> listArtists() async {
    try {
      final data = await _client
          .from('artists')
          .select('id, name, genre_text, created_at')
          .order('name', ascending: true);

      return data.map((row) => Artist.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar artistas: $e');
    }
  }

  Future<Artist?> getArtistById(int artistId) async {
    try {
      final data = await _client
          .from('artists')
          .select('id, name, genre_text, created_at')
          .eq('id', artistId)
          .maybeSingle();

      if (data == null) return null;
      return Artist.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao obter artista: $e');
    }
  }

  Future<List<AlbumListItem>> listAlbumsByArtistId(int artistId) async {
    try {
      // Buscar CDs
      final cdData = await _client
          .from('cd_albums')
          .select(
            'id, title, artist_id, on_shelf, cover_url, created_at',
          )
          .eq('artist_id', artistId)
          .order('id', ascending: true);

      // Buscar Vinis
      final vinylData = await _client
          .from('vinyl_albums')
          .select(
            'id, title, artist_id, on_shelf, cover_url, created_at',
          )
          .eq('artist_id', artistId)
          .order('id', ascending: true);

      final artist = await getArtistById(artistId);

      // Processar CDs
      final cdItems = cdData.map((row) {
        return AlbumListItem(
          albumId: _asInt(row['id']),
          title: row['title'] as String,
          artistId: _asInt(row['artist_id']),
          artistName: artist?.name ?? 'Unknown',
          artistGenreText: artist?.genreText,
          onShelf: row['on_shelf'] as bool,
          coverUrl: row['cover_url'] as String?,
          createdAt: _asDateTime(row['created_at']),
          itemType: ItemType.cd,
        );
      }).toList();

      // Processar Vinis
      final vinylItems = vinylData.map((row) {
        return AlbumListItem(
          albumId: _asInt(row['id']),
          title: row['title'] as String,
          artistId: _asInt(row['artist_id']),
          artistName: artist?.name ?? 'Unknown',
          artistGenreText: artist?.genreText,
          onShelf: row['on_shelf'] as bool,
          coverUrl: row['cover_url'] as String?,
          createdAt: _asDateTime(row['created_at']),
          itemType: ItemType.vinyl,
        );
      }).toList();

      // Combinar e ordenar por ID
      final allItems = [...cdItems, ...vinylItems];
      allItems.sort((a, b) => a.albumId.compareTo(b.albumId));

      return allItems;
    } catch (e) {
      throw AppException(message: 'Falha ao listar álbuns do artista: $e');
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
