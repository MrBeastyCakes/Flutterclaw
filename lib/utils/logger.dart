import 'dart:developer' as developer;

/// Simple logger for Flutterclaw
class AppLogger {
  static void info(String message, {String? tag}) {
    final logTag = tag ?? 'Flutterclaw';
    developer.log('[INFO] $message', name: logTag);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag ?? 'Flutterclaw';
    developer.log('[ERROR] $message', name: logTag, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {String? tag}) {
    final logTag = tag ?? 'Flutterclaw';
    developer.log('[DEBUG] $message', name: logTag);
  }

  static void warning(String message, {String? tag}) {
    final logTag = tag ?? 'Flutterclaw';
    developer.log('[WARN] $message', name: logTag);
  }
}
