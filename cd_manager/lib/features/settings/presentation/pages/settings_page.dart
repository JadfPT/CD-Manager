import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../application/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: themeModeAsync.when(
        loading: () => const LoadingSkeleton(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(width: 220, height: 12),
                    SizedBox(height: 14),
                    SkeletonBox(height: 48, radius: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
        error: (error, _) => AppErrorState(
          message: 'Erro ao carregar definições: $error',
          onRetry: () => ref.invalidate(themeModeControllerProvider),
        ),
        data: (themeMode) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSectionCard(
                title: 'Aparência',
                subtitle: 'Escolhe como o tema é aplicado na aplicação.',
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('Sistema'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Escuro'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    final selectedMode = selection.first;
                    ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(selectedMode);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
