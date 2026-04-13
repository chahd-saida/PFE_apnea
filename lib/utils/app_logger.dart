import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class _ReleaseFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!kReleaseMode) {
      return true;
    }
    return event.level.index >= Level.warning.index;
  }
}

class AppLogger {
  AppLogger()
    : _logger = Logger(
        filter: _ReleaseFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: !kReleaseMode,
          printEmojis: !kReleaseMode,
          dateTimeFormat: !kReleaseMode
              ? DateTimeFormat.onlyTimeAndSinceStart
              : DateTimeFormat.none,
        ),
      );

  final Logger _logger;

  void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

final AppLogger appLogger = AppLogger();
