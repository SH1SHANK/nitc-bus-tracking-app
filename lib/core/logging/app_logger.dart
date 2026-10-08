import 'dart:developer' as developer;

/// Lightweight structured logger that avoids raw `print` calls and integrates with Dart DevTools.
class AppLogger {
  const AppLogger._();

  static void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'Tracklet',
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '⚠️ $message',
      name: tag ?? 'Tracklet',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '❌ $message',
      name: tag ?? 'Tracklet',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String? tag}) {
    developer.log('🔍 $message', name: tag ?? 'Tracklet', level: 500);
  }
}
