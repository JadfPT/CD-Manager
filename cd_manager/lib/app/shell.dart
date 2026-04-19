import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Shell extends StatelessWidget {
  const Shell({required this.child, super.key});

  final Widget child;

  static const _routes = ['/', '/favorites', '/artists', '/loans', '/collections', '/profile'];

  int _selectedIndexFromLocation(String location) {
    if (location == '/' || location.startsWith('/albums/')) return 0;
    if (location.startsWith('/favorites')) return 1;
    if (location.startsWith('/artists')) return 2;
    if (location.startsWith('/loans')) return 3;
    if (location.startsWith('/collections')) return 4;
    if (location.startsWith('/profile') || location.startsWith('/settings')) {
      return 5;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(_routes[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.album), label: 'Coleção'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Artistas'),
          NavigationDestination(icon: Icon(Icons.logout), label: 'Fora'),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark),
            label: 'Coleções',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
