import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/album_list_item.dart';
import '../models/artist.dart';
import '../models/item_type.dart';

class ArtistRepository {
  ArtistRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<void> _ensureCurrentUserIsAdmin() async {
    try {
      final isAdmin = await _client.rpc('current_user_is_admin');
      if (isAdmin != true) {
        throw AppException(message: 'Apenas administradores podem fazer esta ação');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Falha ao validar permissões de admin: $e');
    }
  }

  Future<List<Artist>> listArtists() async {
    try {
      final data = await _client
          .from('artists')
          .select('id, name, genre_text, image_url, created_at')
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
          .select('id, name, genre_text, image_url, created_at')
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
          artistImageUrl: artist?.imageUrl,
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
          artistImageUrl: artist?.imageUrl,
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

  Future<Artist> createArtist({
    required String name,
    String? genreText,
    String? imageUrl,
  }) async {
    await _ensureCurrentUserIsAdmin();

    try {
      final data = await _client
          .from('artists')
          .insert({
            'name': name.trim(),
            'genre_text': genreText?.trim().isEmpty == true ? null : genreText?.trim(),
            'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
          })
          .select('id, name, genre_text, image_url, created_at')
          .single();

      return Artist.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao criar artista: $e');
    }
  }

  Future<Artist> updateArtist({
    required int artistId,
    required String name,
    String? genreText,
    String? imageUrl,
  }) async {
    await _ensureCurrentUserIsAdmin();

    try {
      final data = await _client
          .from('artists')
          .update({
            'name': name.trim(),
            'genre_text': genreText?.trim().isEmpty == true ? null : genreText?.trim(),
            'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
          })
          .eq('id', artistId)
          .select('id, name, genre_text, image_url, created_at')
          .maybeSingle();

      if (data == null) {
        throw AppException(
          message:
              'Sem permissão para editar este artista (RLS/policies) ou artista inexistente.',
        );
      }

      return Artist.fromMap(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Falha ao editar artista: $e');
    }
  }

  Future<String> uploadArtistImage({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    await _ensureCurrentUserIsAdmin();

    final userId = _requireUserId();
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final path = '$userId/artist_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    try {
      await _client.storage.from('artist').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return _client.storage.from('artist').getPublicUrl(path);
    } on StorageException catch (e) {
      final msg = e.message.toLowerCase();
      final isUnauthorized =
          e.statusCode == '403' || msg.contains('row level security');
      if (isUnauthorized) {
        throw AppException(
          message:
              'Sem permissão para upload no bucket artist (RLS). Configura as policies de INSERT/UPDATE/SELECT para o utilizador autenticado/admin.',
        );
      }
      throw AppException(message: 'Falha ao carregar imagem do artista: ${e.message}');
    } catch (e) {
      throw AppException(message: 'Falha ao carregar imagem do artista: $e');
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
