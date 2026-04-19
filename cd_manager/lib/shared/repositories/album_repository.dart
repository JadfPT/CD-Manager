import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/album.dart';
import '../models/album_detail_view.dart';
import '../models/album_list_item.dart';
import '../models/album_loan.dart';
import '../models/artist.dart';
import '../models/item_type.dart';
import '../models/user_album_note.dart';

class AlbumRepository {
  AlbumRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _tableByType(ItemType itemType) =>
      itemType == ItemType.cd ? 'cd_albums' : 'vinyl_albums';

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

  Future<List<Album>> listAlbums({bool? onShelf}) async {
    try {
      var query = _client
          .from('cd_albums')
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
      var query = _client.from('cd_albums').select(
            'id, title, artist_id, on_shelf, cover_url, created_at',
          );

      if (onShelf != null) {
        query = query.eq('on_shelf', onShelf);
      }

      final data = await query.order('id', ascending: true);

      // Get all artist IDs from albums
      final artistIds = data
          .map((row) => _asInt(row['artist_id']))
          .toSet()
          .toList();

      final artistMap = <int, Map<String, dynamic>>{};
      if (artistIds.isNotEmpty) {
        final artists = await _client
            .from('artists')
          .select('id, name, genre_text, image_url, created_at')
            .inFilter('id', artistIds);

        for (final artist in artists) {
          final id = _asInt(artist['id']);
          artistMap[id] = artist;
        }
      }

      var items = data.map((row) {
        final artistId = _asInt(row['artist_id']);
        final artist = artistMap[artistId] ?? {};
        return AlbumListItem(
          albumId: _asInt(row['id']),
          title: row['title'] as String,
          artistId: artistId,
          artistName: (artist['name'] as String?) ?? 'Unknown',
          artistGenreText: artist['genre_text'] as String?,
          artistImageUrl: artist['image_url'] as String?,
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

  Future<AlbumDetailsViewData> getAlbumDetails(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final userId = _requireUserId();

    try {
      final resolvedAlbum = await _fetchAlbumRow(albumId, preferredType: itemType);
      final albumRow = resolvedAlbum.albumRow;
      final resolvedItemType = resolvedAlbum.itemType;
      final itemTypeStr = resolvedItemType == ItemType.cd ? 'cd' : 'vinyl';

      final album = Album.fromMap(albumRow);

      final artistRow = await _client
          .from('artists')
          .select('id, name, genre_text, image_url, created_at')
          .eq('id', _asInt(albumRow['artist_id']))
          .single();
      final artist = Artist.fromMap(artistRow);

      final favoriteRow = await _client
          .from('user_favorite_items')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', itemTypeStr)
          .maybeSingle();

      final noteRow = await _client
          .from('user_item_notes')
          .select('user_id, item_id, note, updated_at, item_type')
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', itemTypeStr)
          .maybeSingle();

      final loanRow = await _client
          .from('item_loans')
          .select(
              'id, item_id, borrowed_by_user_id, borrowed_at, returned_at, item_type')
          .eq('item_id', albumId)
          .eq('item_type', itemTypeStr)
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
        itemType: resolvedItemType,
        isFavorite: favoriteRow != null,
        userNote: noteRow == null ? null : UserAlbumNote.fromMap(noteRow),
        activeLoan: loanRow == null ? null : AlbumLoan.fromMap(loanRow),
        currentUserIsAdmin: currentUserIsAdmin,
      );
    } catch (e) {
      throw AppException(message: 'Falha ao obter detalhe do álbum: $e');
    }
  }

  Future<({Map<String, dynamic> albumRow, ItemType itemType})> _fetchAlbumRow(
    int albumId, {
    required ItemType preferredType,
  }) async {
    final preferredTable = preferredType == ItemType.cd ? 'cd_albums' : 'vinyl_albums';
    final fallbackType = preferredType == ItemType.cd ? ItemType.vinyl : ItemType.cd;
    final fallbackTable = fallbackType == ItemType.cd ? 'cd_albums' : 'vinyl_albums';

    final preferredRow = await _client
        .from(preferredTable)
        .select('id, title, artist_id, on_shelf, cover_url, format_edition, created_at')
        .eq('id', albumId)
        .maybeSingle();

    if (preferredRow != null) {
      return (albumRow: preferredRow, itemType: preferredType);
    }

    final fallbackRow = await _client
        .from(fallbackTable)
        .select('id, title, artist_id, on_shelf, cover_url, format_edition, created_at')
        .eq('id', albumId)
        .maybeSingle();

    if (fallbackRow != null) {
      return (albumRow: fallbackRow, itemType: fallbackType);
    }

    throw AppException(message: 'Falha ao obter detalhe do álbum: item não encontrado');
  }

  Future<List<AlbumListItem>> listAllItemsUnified({
    String? searchText,
    bool? onShelf,
    ItemType? itemTypeFilter,
  }) async {
    try {
      final List<AlbumListItem> allItems = [];

      // Fetch CDs if not filtering for vinyl
      if (itemTypeFilter == null || itemTypeFilter == ItemType.cd) {
        final cdData = await _client
            .from('cd_albums')
            .select('id, title, artist_id, on_shelf, cover_url, created_at');

        final cdItems = cdData.where((row) {
          if (onShelf != null && row['on_shelf'] != onShelf) return false;
          return true;
        }).toList();

        // Get artist data for CDs
        final cdArtistIds = cdItems
            .map((row) => _asInt(row['artist_id']))
            .toSet()
            .toList();

        final artistMap = <int, Map<String, dynamic>>{};
        if (cdArtistIds.isNotEmpty) {
          final artists = await _client
              .from('artists')
              .select('id, name, genre_text, image_url, created_at')
              .inFilter('id', cdArtistIds);

          for (final artist in artists) {
            final id = _asInt(artist['id']);
            artistMap[id] = artist;
          }
        }

        for (final row in cdItems) {
          final artistId = _asInt(row['artist_id']);
          final artist = artistMap[artistId] ?? {};
          allItems.add(AlbumListItem(
            albumId: _asInt(row['id']),
            title: row['title'] as String,
            artistId: artistId,
            artistName: (artist['name'] as String?) ?? 'Unknown',
            artistGenreText: artist['genre_text'] as String?,
            artistImageUrl: artist['image_url'] as String?,
            onShelf: row['on_shelf'] as bool,
            coverUrl: row['cover_url'] as String?,
            createdAt: _asDateTime(row['created_at']),
            itemType: ItemType.cd,
          ));
        }
      }

      // Fetch Vinyls if not filtering for CD
      if (itemTypeFilter == null || itemTypeFilter == ItemType.vinyl) {
        final vinylData = await _client
            .from('vinyl_albums')
            .select('id, title, artist_id, on_shelf, cover_url, created_at');

        final vinylItems = vinylData.where((row) {
          if (onShelf != null && row['on_shelf'] != onShelf) return false;
          return true;
        }).toList();

        // Get artist data for Vinyls
        final vinylArtistIds = vinylItems
            .map((row) => _asInt(row['artist_id']))
            .toSet()
            .toList();

        final artistMap = <int, Map<String, dynamic>>{};
        if (vinylArtistIds.isNotEmpty) {
          final artists = await _client
              .from('artists')
              .select('id, name, genre_text, image_url, created_at')
              .inFilter('id', vinylArtistIds);

          for (final artist in artists) {
            final id = _asInt(artist['id']);
            artistMap[id] = artist;
          }
        }

        for (final row in vinylItems) {
          final artistId = _asInt(row['artist_id']);
          final artist = artistMap[artistId] ?? {};
          allItems.add(AlbumListItem(
            albumId: _asInt(row['id']),
            title: row['title'] as String,
            artistId: artistId,
            artistName: (artist['name'] as String?) ?? 'Unknown',
            artistGenreText: artist['genre_text'] as String?,
            artistImageUrl: artist['image_url'] as String?,
            onShelf: row['on_shelf'] as bool,
            coverUrl: row['cover_url'] as String?,
            createdAt: _asDateTime(row['created_at']),
            itemType: ItemType.vinyl,
          ));
        }
      }

      // Apply search filter
      var filteredItems = allItems;
      final normalizedSearch = searchText?.trim().toLowerCase();
      if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
        filteredItems = filteredItems
            .where(
              (item) =>
                  item.title.toLowerCase().contains(normalizedSearch) ||
                  item.artistName.toLowerCase().contains(normalizedSearch),
            )
            .toList();
      }

      // Sort by item type, then by ID
      filteredItems.sort((a, b) {
        final typeCompare = a.itemType.value.compareTo(b.itemType.value);
        if (typeCompare != 0) return typeCompare;
        return a.albumId.compareTo(b.albumId);
      });

      return filteredItems;
    } catch (e) {
      throw AppException(message: 'Falha ao obter coleção: $e');
    }
  }

  Future<Album> createItem({
    required ItemType itemType,
    required String title,
    required int artistId,
    String? formatEdition,
    String? coverUrl,
  }) async {
    await _ensureCurrentUserIsAdmin();

    final table = _tableByType(itemType);

    try {
      final data = await _client
          .from(table)
          .insert({
            'title': title.trim(),
            'artist_id': artistId,
            'on_shelf': true,
            'format_edition': formatEdition?.trim().isEmpty == true ? null : formatEdition?.trim(),
            'cover_url': coverUrl?.trim().isEmpty == true ? null : coverUrl?.trim(),
          })
          .select('id, title, artist_id, on_shelf, cover_url, format_edition, created_at')
          .single();

      return Album.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao criar item: $e');
    }
  }

  Future<Album> updateItem({
    required ItemType itemType,
    required int itemId,
    required String title,
    required int artistId,
    String? formatEdition,
    String? coverUrl,
  }) async {
    await _ensureCurrentUserIsAdmin();

    final table = _tableByType(itemType);

    try {
      final data = await _client
          .from(table)
          .update({
            'title': title.trim(),
            'artist_id': artistId,
            'format_edition': formatEdition?.trim().isEmpty == true ? null : formatEdition?.trim(),
            'cover_url': coverUrl?.trim().isEmpty == true ? null : coverUrl?.trim(),
          })
          .eq('id', itemId)
          .select('id, title, artist_id, on_shelf, cover_url, format_edition, created_at')
          .single();

      return Album.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao editar item: $e');
    }
  }

  Future<String> uploadCover({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    await _ensureCurrentUserIsAdmin();

    final userId = _requireUserId();
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final path = '$userId/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    try {
      await _client.storage.from('covers').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return _client.storage.from('covers').getPublicUrl(path);
    } on StorageException catch (e) {
      final msg = e.message.toLowerCase();
      final isUnauthorized =
          e.statusCode == '403' || msg.contains('row level security');
      if (isUnauthorized) {
        throw AppException(
          message:
              'Sem permissão para upload no bucket covers (RLS). Configura as policies de INSERT/UPDATE/SELECT para o utilizador autenticado/admin.',
        );
      }
      throw AppException(message: 'Falha ao carregar capa: ${e.message}');
    } catch (e) {
      throw AppException(message: 'Falha ao carregar capa: $e');
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
