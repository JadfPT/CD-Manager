import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../shared/models/item_type.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is AuthSuccess) {
        if (isLoggingIn) {
          return '/';
        }
      } else if (authState is AuthInitial) {
        if (!isLoggingIn) {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => Shell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AlbumsPage(),
          ),
          GoRoute(
            path: '/albums/:albumId',
            builder: (context, state) {
              final albumId = int.tryParse(state.pathParameters['albumId'] ?? '');
              if (albumId == null) {
                return const Scaffold(
                  body: Center(child: Text('ID de álbum inválido')),
                );
              }
              
              // Extract itemType from extra, default to CD
              final itemType = state.extra is ItemType 
                  ? state.extra as ItemType 
                  : ItemType.cd;
              
              return AlbumDetailsPage(
                albumId: albumId,
                itemType: itemType,
              );
            },
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/artists',
            builder: (context, state) => const ArtistsPage(),
          ),
          GoRoute(
            path: '/artists/:artistId',
            builder: (context, state) {
              final artistId = int.tryParse(state.pathParameters['artistId'] ?? '');
              if (artistId == null) {
                return const Scaffold(
                  body: Center(child: Text('ID de artista inválido')),
                );
              }
              return ArtistDetailsPage(artistId: artistId);
            },
          ),
          GoRoute(
            path: '/loans',
            builder: (context, state) => const LoansPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
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
