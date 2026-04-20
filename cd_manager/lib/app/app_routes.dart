class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const favorites = '/favorites';
  static const artists = '/artists';
  static const loans = '/loans';
  static const profile = '/profile';
  static const settings = '/settings';
  static const random = '/random';
  static const adminWishlist = '/admin/wishlist';
  static const collections = '/collections';
  static const collectionsNew = '/collections/new';

  static String albumDetails(int albumId) => '/albums/$albumId';
  static String artistDetails(int artistId) => '/artists/$artistId';
  static String adminNewItem(String itemType) => '/admin/items/new/$itemType';
  static String adminEditArtist(int artistId) => '/admin/artists/$artistId/edit';
  static String adminEditItem(String itemType, int itemId) =>
      '/admin/items/$itemType/$itemId/edit';
  static String collectionDetails(int collectionId) => '/collections/$collectionId';
  static String collectionEdit(int collectionId) => '/collections/$collectionId/edit';
  static String collectionAddItem(int collectionId) =>
      '/collections/$collectionId/add-item';
}
