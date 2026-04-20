import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/active_loan_details.dart';
import '../models/active_loan_list_item.dart';
import '../models/album_loan.dart';
import '../models/album_list_item.dart';
import '../models/item_type.dart';

class LoanRepository {
  LoanRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _itemTypeToDb(ItemType itemType) =>
      itemType == ItemType.cd ? 'cd' : 'vinyl';

  Future<List<AlbumLoan>> listActiveLoans() async {
    try {
      debugPrint('[LoanRepository] listActiveLoans');
      final data = await _client
          .from('item_loans')
          .select('id, item_id, borrowed_by_user_id, borrowed_at, returned_at, item_type')
          .isFilter('returned_at', null)
          .order('borrowed_at', ascending: false);

      return data.map((row) => AlbumLoan.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar empréstimos ativos: $e');
    }
  }

  Future<AlbumLoan?> getActiveLoanForAlbum(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final itemTypeDb = _itemTypeToDb(itemType);

    try {
      debugPrint('[LoanRepository] getActiveLoanForAlbum albumId=$albumId type=$itemTypeDb');
      final data = await _client
          .from('item_loans')
          .select('id, item_id, borrowed_by_user_id, borrowed_at, returned_at, item_type')
          .eq('item_id', albumId)
          .eq('item_type', itemTypeDb)
          .isFilter('returned_at', null)
          .order('borrowed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return AlbumLoan.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao obter empréstimo ativo: $e');
    }
  }

  Future<ActiveLoanDetails?> getActiveLoanDetailsForAlbum(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final loan = await getActiveLoanForAlbum(albumId, itemType: itemType);
    if (loan == null) return null;

    try {
      debugPrint('[LoanRepository] getActiveLoanDetailsForAlbum albumId=$albumId type=${_itemTypeToDb(itemType)}');
      final borrower = await _client
          .from('profiles')
          .select('id, username, display_name')
          .eq('id', loan.borrowedByUserId)
          .maybeSingle();

      return ActiveLoanDetails(
        loan: loan,
        borrowerDisplayName: borrower?['display_name'] as String?,
        borrowerUsername: borrower?['username'] as String?,
      );
    } catch (e) {
      throw AppException(
        message: 'Falha ao obter detalhes do empréstimo ativo: $e',
      );
    }
  }

  Future<List<ActiveLoanListItem>> listActiveLoanListItems() async {
    try {
      debugPrint('[LoanRepository] listActiveLoanListItems');
      // Buscar empréstimos de CDs
      final cdRows = await _client
          .from('item_loans')
          .select('id, item_id, borrowed_by_user_id, borrowed_at, item_type')
          .eq('item_type', 'cd')
          .isFilter('returned_at', null)
          .order('borrowed_at', ascending: false);

      // Buscar empréstimos de Vinis
      final vinylRows = await _client
          .from('item_loans')
          .select('id, item_id, borrowed_by_user_id, borrowed_at, item_type')
          .eq('item_type', 'vinyl')
          .isFilter('returned_at', null)
          .order('borrowed_at', ascending: false);

      // Combinar todos os empréstimos
      final allRows = [...cdRows, ...vinylRows];

      // Separar IDs por tipo
      final cdIds = cdRows.map((row) => _asInt(row['item_id'])).toSet().toList();
      final vinylIds = vinylRows.map((row) => _asInt(row['item_id'])).toSet().toList();

      // Buscar dados dos álbuns de CD
      final cdAlbumMap = <int, Map<String, dynamic>>{};
      final cdArtistIds = <int>[];
      if (cdIds.isNotEmpty) {
        final cdAlbums = await _client
            .from('cd_albums')
            .select('id, title, artist_id, cover_url')
            .inFilter('id', cdIds);

        for (final album in cdAlbums) {
          final id = _asInt(album['id']);
          cdAlbumMap[id] = album;
          cdArtistIds.add(_asInt(album['artist_id']));
        }
      }

      // Buscar dados dos álbuns de Vinil
      final vinylAlbumMap = <int, Map<String, dynamic>>{};
      final vinylArtistIds = <int>[];
      if (vinylIds.isNotEmpty) {
        final vinylAlbums = await _client
            .from('vinyl_albums')
            .select('id, title, artist_id, cover_url')
            .inFilter('id', vinylIds);

        for (final album in vinylAlbums) {
          final id = _asInt(album['id']);
          vinylAlbumMap[id] = album;
          vinylArtistIds.add(_asInt(album['artist_id']));
        }
      }

      // Buscar artistas
      final allArtistIds = <int>{...cdArtistIds, ...vinylArtistIds}.toList();
      final artistMap = <int, Map<String, dynamic>>{};
      if (allArtistIds.isNotEmpty) {
        final artists = await _client
            .from('artists')
             .select('id, name, genre_text, image_url')
            .inFilter('id', allArtistIds);
        for (final artist in artists) {
          final id = _asInt(artist['id']);
          artistMap[id] = artist;
        }
      }

      // Buscar dados dos emprestadores
      final borrowerIds = allRows
          .map((row) => row['borrowed_by_user_id'] as String)
          .toSet()
          .toList();

      final borrowerMap = <String, Map<String, dynamic>>{};
      if (borrowerIds.isNotEmpty) {
        final profiles = await _client
            .from('profiles')
            .select('id, username, display_name')
            .inFilter('id', borrowerIds);

        for (final profile in profiles) {
          final id = profile['id'] as String;
          borrowerMap[id] = profile;
        }
      }

      // Processar todos os empréstimos
      final result = allRows.map((row) {
        final itemType = row['item_type'] as String;
        final albumId = _asInt(row['item_id']);
        
        // Pegar dados do álbum baseado no tipo
        final albumMap = itemType == 'cd' ? cdAlbumMap : vinylAlbumMap;
        final album = albumMap[albumId] ?? {};
        
        final artistId = _asInt(album['artist_id'] ?? 0);
        final artist = artistMap[artistId] ?? {};
        final borrowerId = row['borrowed_by_user_id'] as String;
        final borrowerProfile = borrowerMap[borrowerId];

        return ActiveLoanListItem(
          loanId: _asInt(row['id']),
          albumId: albumId,
          title: (album['title'] as String?) ?? 'Unknown',
          artistName: (artist['name'] as String?) ?? 'Unknown',
          coverUrl: album['cover_url'] as String?,
          borrowedByUserId: borrowerId,
          borrowedAt: _asDateTime(row['borrowed_at'])!,
          borrowerDisplayName: borrowerProfile?['display_name'] as String?,
          borrowerUsername: borrowerProfile?['username'] as String?,
          itemType: itemType == 'vinyl' ? ItemType.vinyl : ItemType.cd,
        );
      }).toList();

      // Ordenar por data de empréstimo (mais recentes primeiro)
      result.sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));

      return result;
    } catch (e) {
      throw AppException(message: 'Falha ao listar itens emprestados: $e');
    }
  }

  Future<List<AlbumListItem>> listOutsideShelfAlbums() async {
    try {
      debugPrint('[LoanRepository] listOutsideShelfAlbums');

      final cdData = await _client
          .from('cd_albums')
          .select('id, title, artist_id, on_shelf, cover_url, created_at')
          .eq('on_shelf', false)
          .order('id', ascending: true);

      final vinylData = await _client
          .from('vinyl_albums')
          .select('id, title, artist_id, on_shelf, cover_url, created_at')
          .eq('on_shelf', false)
          .order('id', ascending: true);

      final allRows = [
        ...cdData.map((row) => (row: row, itemType: ItemType.cd)),
        ...vinylData.map((row) => (row: row, itemType: ItemType.vinyl)),
      ];

      final artistIds = allRows
          .map((entry) => _asInt(entry.row['artist_id']))
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

      return allRows.map((entry) {
        final row = entry.row;
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
          itemType: entry.itemType,
        );
      }).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar itens fora da prateleira: $e');
    }
  }

  Future<void> borrowAlbum(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final itemTypeDb = _itemTypeToDb(itemType);

    try {
      debugPrint('[LoanRepository] borrowAlbum albumId=$albumId type=$itemTypeDb');
      await _client.rpc(
        'borrow_item',
        params: {'p_item_type': itemTypeDb, 'p_item_id': albumId},
      );
    } catch (e) {
      throw AppException(message: 'Falha ao emprestar item: $e');
    }
  }

  Future<void> returnAlbum(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final itemTypeDb = _itemTypeToDb(itemType);

    try {
      debugPrint('[LoanRepository] returnAlbum albumId=$albumId type=$itemTypeDb');
      await _client.rpc(
        'return_item',
        params: {'p_item_type': itemTypeDb, 'p_item_id': albumId},
      );
    } catch (e) {
      throw AppException(message: 'Falha ao devolver item: $e');
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
