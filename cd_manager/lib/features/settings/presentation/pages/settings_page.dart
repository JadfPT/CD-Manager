import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/application/ui_action_executor.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../application/settings_providers.dart';
import '../widgets/settings_section.dart';
import '../widgets/theme_mode_selector.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _onThemeModeChanged(
    BuildContext context,
    WidgetRef ref,
    ThemeMode selectedMode,
  ) async {
    final label = switch (selectedMode) {
      ThemeMode.system => 'sistema',
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'escuro',
    };

    final success = await UiActionExecutor.run(
      context,
      actionName: 'set_theme_mode_$label',
      logCategory: 'settings.ui',
      action: () => ref.read(themeModeControllerProvider.notifier).setThemeMode(selectedMode),
      errorMessage: 'Não foi possível atualizar tema.',
    );

    if (success && context.mounted) {
      AppFeedback.info(context, 'Tema atualizado para $label.');
    }
  }

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
              SettingsSection(
                title: 'Preferências da app',
                subtitle: 'As definições aqui afetam o comportamento visual da aplicação.',
                child: Text(
                  'O perfil é usado para identidade da conta. Esta página é dedicada apenas à experiência da app.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              SettingsSection(
                title: 'Aparência',
                subtitle: 'Escolhe entre modo do sistema, claro ou escuro.',
                child: ThemeModeSelector(
                  themeMode: themeMode,
                  onChanged: (selectedMode) =>
                      _onThemeModeChanged(context, ref, selectedMode),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
