import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF1DB854);
  static const _surfaceDark = Color(0xFF0D1118);
  static const _surfaceDarkAlt = Color(0xFF141B24);
  static const _surfaceDarkElevated = Color(0xFF1A2430);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F7F3),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).surfaceContainer,
      foregroundColor: const Color(0xFF101214),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F2EC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _seedColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade900,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: _seedColor,
      behavior: SnackBarBehavior.floating,
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: _surfaceDark,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: _surfaceDarkAlt,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: _surfaceDarkAlt,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceDarkElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _seedColor,
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8E9AA9)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E222B),
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: _seedColor,
      behavior: SnackBarBehavior.floating,
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: _seedColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      labelColor: Colors.white,
      unselectedLabelColor: const Color(0xFFAAB5C2),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.08),
      thickness: 1,
    ),
  );
}
