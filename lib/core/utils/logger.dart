import 'dart:developer' as dev;

class AppLogger {
  AppLogger._();

  static void debug(String message, {String tag = 'DEBUG', Object? error, StackTrace? stackTrace}) {
    dev.log('🔍 [$tag] $message', name: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String tag = 'INFO'}) {
    dev.log('ℹ️ [$tag] $message', name: tag);
  }

  static void warning(String message, {String tag = 'WARN', Object? error}) {
    dev.log('⚠️ [$tag] $message', name: tag, error: error);
  }

  static void error(String message, {String tag = 'ERROR', Object? error, StackTrace? stackTrace}) {
    dev.log('🛑 [$tag] $message', name: tag, error: error, stackTrace: stackTrace);
  }
}
