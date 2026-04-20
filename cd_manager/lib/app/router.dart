import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import 'shell.dart';
import '../features/albums/presentation/pages/albums_page.dart';
import '../features/albums/presentation/pages/album_details_page.dart';
import '../features/favorites/presentation/pages/favorites_page.dart';
import '../features/artists/presentation/pages/artists_page.dart';
import '../features/artists/presentation/pages/artist_details_page.dart';
import '../features/loans/presentation/pages/loans_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/random/presentation/pages/random_page.dart';
import '../features/admin/presentation/pages/admin_item_form_page.dart';
import '../features/admin/presentation/pages/admin_artist_form_page.dart';
import '../features/admin/presentation/pages/wishlist_admin_page.dart';
import '../features/collections/presentation/pages/collections_page.dart';
import '../features/collections/presentation/pages/collection_detail_page.dart';
import '../features/collections/presentation/pages/collection_form_page.dart';
import '../features/collections/presentation/pages/add_item_to_collection_page.dart';
import '../shared/models/item_type.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (authState is AuthSuccess) {
        if (isLoggingIn) {
          return AppRoutes.home;
        }
      } else if (authState is AuthInitial) {
        if (!isLoggingIn) {
          return AppRoutes.login;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadePage(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _fadePage(state, const RegisterPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => Shell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _fadePage(state, const AlbumsPage()),
          ),
          GoRoute(
            path: '/albums/:albumId',
            pageBuilder: (context, state) {
              final albumId = int.tryParse(state.pathParameters['albumId'] ?? '');
              if (albumId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de álbum inválido')),
                  ),
                );
              }

              // Prefer query param (?type=cd|vinyl), fallback to extra, then CD
              final typeFromQuery = (state.uri.queryParameters['type'] ?? '').toLowerCase();
              final itemType = typeFromQuery == 'vinyl'
                  ? ItemType.vinyl
                  : typeFromQuery == 'cd'
                      ? ItemType.cd
                      : state.extra is ItemType
                          ? state.extra as ItemType
                          : ItemType.cd;
              
              return _fadePage(
                state,
                AlbumDetailsPage(
                  albumId: albumId,
                  itemType: itemType,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.favorites,
            pageBuilder: (context, state) => _fadePage(state, const FavoritesPage()),
          ),
          GoRoute(
            path: AppRoutes.artists,
            pageBuilder: (context, state) => _fadePage(state, const ArtistsPage()),
          ),
          GoRoute(
            path: '/artists/:artistId',
            pageBuilder: (context, state) {
              final artistId = int.tryParse(state.pathParameters['artistId'] ?? '');
              if (artistId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de artista inválido')),
                  ),
                );
              }
              return _fadePage(state, ArtistDetailsPage(artistId: artistId));
            },
          ),
          GoRoute(
            path: AppRoutes.loans,
            pageBuilder: (context, state) => _fadePage(state, const LoansPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _fadePage(state, const ProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _fadePage(state, const SettingsPage()),
          ),
          GoRoute(
            path: AppRoutes.random,
            pageBuilder: (context, state) => _fadePage(state, const RandomPage()),
          ),
          GoRoute(
            path: '/admin/items/new/:itemType',
            pageBuilder: (context, state) {
              final itemTypeRaw = state.pathParameters['itemType'] ?? 'cd';
              final itemType = itemTypeRaw == 'vinyl' ? ItemType.vinyl : ItemType.cd;
              return _fadePage(state, AdminItemFormPage.create(itemType: itemType));
            },
          ),
          GoRoute(
            path: '/admin/artists/new',
            pageBuilder: (context, state) => _fadePage(state, const AdminArtistFormPage.create()),
          ),
          GoRoute(
            path: '/admin/artists/:artistId/edit',
            pageBuilder: (context, state) {
              final artistId = int.tryParse(state.pathParameters['artistId'] ?? '');
              if (artistId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de artista inválido')),
                  ),
                );
              }
              return _fadePage(state, AdminArtistFormPage.edit(artistId: artistId));
            },
          ),
          GoRoute(
            path: AppRoutes.adminWishlist,
            pageBuilder: (context, state) => _fadePage(state, const WishlistAdminPage()),
          ),
          GoRoute(
            path: AppRoutes.collections,
            pageBuilder: (context, state) => _fadePage(state, const CollectionsPage()),
          ),
          GoRoute(
            path: AppRoutes.collectionsNew,
            pageBuilder: (context, state) => _fadePage(state, const CollectionFormPage.create()),
          ),
          GoRoute(
            path: '/collections/:collectionId',
            pageBuilder: (context, state) {
              final collectionId = int.tryParse(state.pathParameters['collectionId'] ?? '');
              if (collectionId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de coleção inválido')),
                  ),
                );
              }
              return _fadePage(state, CollectionDetailPage(collectionId: collectionId));
            },
          ),
          GoRoute(
            path: '/collections/:collectionId/edit',
            pageBuilder: (context, state) {
              final collectionId = int.tryParse(state.pathParameters['collectionId'] ?? '');
              if (collectionId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de coleção inválido')),
                  ),
                );
              }
              return _fadePage(state, CollectionFormPage.edit(collectionId: collectionId));
            },
          ),
          GoRoute(
            path: '/collections/:collectionId/add-item',
            pageBuilder: (context, state) {
              final collectionId = int.tryParse(state.pathParameters['collectionId'] ?? '');
              if (collectionId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de coleção inválido')),
                  ),
                );
              }
              return _fadePage(state, AddItemToCollectionPage(collectionId: collectionId));
            },
          ),
          GoRoute(
            path: '/admin/items/:itemType/:itemId/edit',
            pageBuilder: (context, state) {
              final itemTypeRaw = state.pathParameters['itemType'] ?? 'cd';
              final itemType = itemTypeRaw == 'vinyl' ? ItemType.vinyl : ItemType.cd;
              final itemId = int.tryParse(state.pathParameters['itemId'] ?? '');
              if (itemId == null) {
                return _fadePage(
                  state,
                  const Scaffold(
                    body: Center(child: Text('ID de item inválido')),
                  ),
                );
              }
              return _fadePage(
                state,
                AdminItemFormPage.edit(itemType: itemType, itemId: itemId),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Text('Rota não encontrada: ${state.error}'),
      ),
    ),
  );
});

CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final offset = Tween<Offset>(begin: const Offset(0.02, 0.02), end: Offset.zero)
          .animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
