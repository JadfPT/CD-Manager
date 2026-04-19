import 'package:flutter/material.dart';

class UserSettings {
  const UserSettings({
    required this.userId,
    this.themeMode = ThemeMode.system,
  });

  final String userId;
  final ThemeMode themeMode;

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['user_id'] as String,
      themeMode: _themeModeFromString(map['theme_mode'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'theme_mode': _themeModeToString(themeMode),
    };
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
