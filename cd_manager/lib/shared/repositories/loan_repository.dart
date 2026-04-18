import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/active_loan_details.dart';
import '../models/active_loan_list_item.dart';
import '../models/album_loan.dart';
import '../models/album_list_item.dart';

class LoanRepository {
  LoanRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<AlbumLoan>> listActiveLoans() async {
    try {
      final data = await _client
          .from('album_loans')
          .select('id, album_id, borrowed_by_user_id, borrowed_at, returned_at')
          .isFilter('returned_at', null)
          .order('borrowed_at', ascending: false);

      return data.map((row) => AlbumLoan.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar empréstimos ativos: $e');
    }
  }

  Future<AlbumLoan?> getActiveLoanForAlbum(int albumId) async {
    try {
      final data = await _client
          .from('album_loans')
          .select('id, album_id, borrowed_by_user_id, borrowed_at, returned_at')
          .eq('album_id', albumId)
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

  Future<ActiveLoanDetails?> getActiveLoanDetailsForAlbum(int albumId) async {
    final loan = await getActiveLoanForAlbum(albumId);
    if (loan == null) return null;

    try {
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
      final rows = await _client
          .from('album_loans')
          .select(
            'id, album_id, borrowed_by_user_id, borrowed_at, '
            'albums!inner(id, title, artist_id, cover_url, '
            'artists!inner(id, name))',
          )
          .isFilter('returned_at', null)
          // Ordered by album id to keep the outside-shelf inventory stable and easy to scan.
          .order('album_id', ascending: true);

      final borrowerIds = rows
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

      return rows.map((row) {
        final albumMap = row['albums'] as Map<String, dynamic>;
        final artistMap = albumMap['artists'] as Map<String, dynamic>;
        final borrowerId = row['borrowed_by_user_id'] as String;
        final borrowerProfile = borrowerMap[borrowerId];

        return ActiveLoanListItem(
          loanId: _asInt(row['id']),
          albumId: _asInt(row['album_id']),
          title: albumMap['title'] as String,
          artistName: artistMap['name'] as String,
          coverUrl: albumMap['cover_url'] as String?,
          borrowedByUserId: borrowerId,
          borrowedAt: _asDateTime(row['borrowed_at'])!,
          borrowerDisplayName: borrowerProfile?['display_name'] as String?,
          borrowerUsername: borrowerProfile?['username'] as String?,
        );
      }).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar CDs fora da prateleira: $e');
    }
  }

  Future<List<AlbumListItem>> listOutsideShelfAlbums() async {
    try {
      final data = await _client
          .from('albums')
          .select(
            'id, title, artist_id, on_shelf, cover_url, created_at, '
            'artists!inner(id, name, genre_text, created_at)',
          )
          .eq('on_shelf', false)
          .order('id', ascending: true);

      return data.map((row) {
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
    } catch (e) {
      throw AppException(message: 'Falha ao listar CDs fora da prateleira: $e');
    }
  }

  Future<void> borrowAlbum(int albumId) async {
    try {
      await _client.rpc('borrow_album', params: {'p_album_id': albumId});
    } catch (e) {
      throw AppException(message: 'Falha ao emprestar CD: $e');
    }
  }

  Future<void> returnAlbum(int albumId) async {
    try {
      await _client.rpc('return_album', params: {'p_album_id': albumId});
    } catch (e) {
      throw AppException(message: 'Falha ao devolver CD: $e');
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
