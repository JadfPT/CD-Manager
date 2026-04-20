import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final authState = ref.watch(authProvider);
    if (authState is! AuthSuccess) {
      AppLogger.info('theme build unauthenticated -> system', category: 'settings');
      return ThemeMode.system;
    }

    final repository = ref.read(settingsRepositoryProvider);
    final settings = await repository.getCurrentUserSettings();
    AppLogger.info(
      'theme loaded mode=${settings?.themeMode.name ?? ThemeMode.system.name}',
      category: 'settings',
    );
    return settings?.themeMode ?? ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final previousState = state;
    state = const AsyncLoading<ThemeMode>().copyWithPrevious(state);

    try {
      AppLogger.info('setThemeMode start mode=${mode.name}', category: 'settings');
      final authState = ref.read(authProvider);
      if (authState is! AuthSuccess) {
        state = AsyncData(mode);
        AppLogger.warning('setThemeMode unauthenticated fallback', category: 'settings');
        return;
      }

      final repository = ref.read(settingsRepositoryProvider);
      await repository.upsertThemeMode(mode);
      state = AsyncData(mode);
      AppLogger.info('setThemeMode success mode=${mode.name}', category: 'settings');
    } catch (error, stackTrace) {
      AppLogger.error(
        'setThemeMode failed mode=${mode.name}',
        category: 'settings',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError<ThemeMode>(error, stackTrace).copyWithPrevious(previousState);
      rethrow;
    }
  }
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
