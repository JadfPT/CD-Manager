import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  SettingsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<UserSettings?> getCurrentUserSettings() async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_settings')
          .select('user_id, theme_mode')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserSettings.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao obter definições: $e');
    }
  }

  Future<UserSettings> upsertThemeMode(ThemeMode mode) async {
    final userId = _requireUserId();

    final themeModeValue = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };

    try {
      final data = await _client
          .from('user_settings')
          .upsert(
            {
              'user_id': userId,
              'theme_mode': themeModeValue,
            },
            onConflict: 'user_id',
          )
          .select('user_id, theme_mode')
          .single();

      return UserSettings.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao guardar tema: $e');
    }
  }
}
