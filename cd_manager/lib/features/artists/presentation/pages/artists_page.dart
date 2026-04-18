import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../application/artist_providers.dart';

class ArtistsPage extends ConsumerWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Artistas')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(artistsProvider);
          await ref.read(artistsProvider.future);
        },
        child: artistsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(artistsProvider),
                ),
              ),
            ],
          ),
          data: (artists) {
            if (artists.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const AppEmptyState(
                      title: 'Sem artistas',
                      subtitle: 'Ainda não existem artistas registados.',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: artists.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final artist = artists[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(artist.name),
                  subtitle: Text(
                    artist.genreText == null || artist.genreText!.trim().isEmpty
                        ? 'Sem género'
                        : artist.genreText!,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/artists/${artist.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
