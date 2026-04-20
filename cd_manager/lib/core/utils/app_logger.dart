import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {String category = 'app'}) {
    developer.log(message, name: 'CDManager.$category');
  }

  static void warning(String message, {String category = 'app'}) {
    developer.log(message, name: 'CDManager.$category', level: 900);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String category = 'app',
  }) {
    developer.log(
      message,
      name: 'CDManager.$category',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
