import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return ThemeMode.system;
    }

    final repository = ref.read(settingsRepositoryProvider);
    final settings = await repository.getCurrentUserSettings();
    return settings?.themeMode ?? ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);

    final authState = ref.read(authProvider);
    if (authState is! AuthSuccess) {
      return;
    }

    final repository = ref.read(settingsRepositoryProvider);
    await repository.upsertThemeMode(mode);
  }
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
