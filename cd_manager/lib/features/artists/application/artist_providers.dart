import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/album_list_item.dart';
import '../../../shared/models/artist.dart';
import '../../../shared/repositories/artist_repository.dart';

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepository();
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.listArtists();
});

final artistByIdProvider = FutureProvider.family<Artist?, int>((ref, artistId) {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.getArtistById(artistId);
});

final artistAlbumsProvider =
    FutureProvider.family<List<AlbumListItem>, int>((ref, artistId) {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.listAlbumsByArtistId(artistId);
});

class ArtistDetailsData {
  const ArtistDetailsData({
    required this.artist,
    required this.albums,
  });

  final Artist? artist;
  final List<AlbumListItem> albums;
}

final artistDetailsProvider =
    FutureProvider.family<ArtistDetailsData, int>((ref, artistId) async {
  final artist = await ref.watch(artistByIdProvider(artistId).future);
  final albums = await ref.watch(artistAlbumsProvider(artistId).future);
  return ArtistDetailsData(artist: artist, albums: albums);
});
