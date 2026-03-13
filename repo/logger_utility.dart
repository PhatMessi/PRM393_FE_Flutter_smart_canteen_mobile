/**
 * Logger Utility
 * 
 * Simple logging system cho development
 * Giúp debug dễ dàng hơn
 */

enum LogLevel { debug, info, warning, error, fatal }

class Logger {
  static const String _tag = 'SmartCanteen';
  static bool _debugMode = true;

  static void setDebugMode(bool enable) {
    _debugMode = enable;
  }

  /// Log debug message
  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag, error, stackTrace);
  }

  /// Log info message
  static void info(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag, error, stackTrace);
  }

  /// Log warning message
  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag, error, stackTrace);
  }

  /// Log error message
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag, error, stackTrace);
  }

  /// Log fatal message
  static void fatal(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, tag, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message,
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    if (!_debugMode && level == LogLevel.debug) return;

    final displayTag = tag ?? _tag;
    final timestamp = DateTime.now().toString();
    final levelName = level.toString().split('.').last.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln('[$timestamp] [$levelName] [$displayTag]');
    buffer.write(message);

    if (error != null) {
      buffer.writeln('\nError: $error');
    }

    if (stackTrace != null) {
      buffer.writeln('\nStackTrace:\n$stackTrace');
    }

    final output = buffer.toString();

    // In ra console
    print(output);
  }

  /// Measure execution time của một function
  static Future<T> measure<T>(
    String label,
    Future<T> Function() fn, {
    String? tag,
  }) async {
    final startTime = DateTime.now();
    try {
      final result = await fn();
      final duration = DateTime.now().difference(startTime);
      info(
        '$label completed in ${duration.inMilliseconds}ms',
        tag: tag ?? 'Performance',
      );
      return result;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      error(
        '$label failed after ${duration.inMilliseconds}ms',
        tag: tag ?? 'Performance',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Measure execution time của synchronous function
  static T measureSync<T>(
    String label,
    T Function() fn, {
    String? tag,
  }) {
    final startTime = DateTime.now();
    try {
      final result = fn();
      final duration = DateTime.now().difference(startTime);
      info(
        '$label completed in ${duration.inMilliseconds}ms',
        tag: tag ?? 'Performance',
      );
      return result;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      error(
        '$label failed after ${duration.inMilliseconds}ms',
        tag: tag ?? 'Performance',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
