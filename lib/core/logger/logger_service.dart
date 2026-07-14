import 'package:flutter/foundation.dart';

enum LogLevel { off, error, warning, info, debug, trace }

extension LogLevelExtension on LogLevel {
  String get description {
    switch (this) {
      case LogLevel.off:
        return "Off";
      case LogLevel.error:
        return "Error";
      case LogLevel.warning:
        return "Warning";
      case LogLevel.info:
        return "Info";
      case LogLevel.debug:
        return "Debug (Default)";
      case LogLevel.trace:
        return "Trace";
    }
  }
}

class Log {
  final dynamic className;

  static const _red = 196;
  static const _blue = 12;
  static const _green = 34;
  static const _orange = 208;

  Log(this.className);

  // debug
  void d(dynamic message, {dynamic tag}) =>
      _print(className, message, 69, LogLevel.debug, tag: tag);

  static void debug(Type className, dynamic message, {dynamic tag}) =>
      _print(className, message, 69, LogLevel.debug, tag: tag);

  // error
  void e(dynamic message, {StackTrace? stackTrace, dynamic tag}) => _print(
    className,
    message,
    _red,
    stackTrace != null ? LogLevel.trace : LogLevel.error,
    tag: tag,
  );

  static void error(
    Type className,
    dynamic message, {
    StackTrace? stackTrace,
    dynamic tag,
  }) => _print(
    className,
    message,
    _red,
    stackTrace != null ? LogLevel.trace : LogLevel.error,
    tag: tag,
  );

  // info
  void i(dynamic message, {dynamic tag}) =>
      _print(className, message, _blue, LogLevel.info, tag: tag);

  static void info(Type className, dynamic message, {dynamic tag}) =>
      _print(className, message, _blue, LogLevel.info, tag: tag);

  // warning
  void w(dynamic message, {dynamic tag}) =>
      _print(className, message, _blue, LogLevel.warning, tag: tag);

  static void warn(Type className, dynamic message, {dynamic tag}) =>
      _print(className, message, _orange, LogLevel.warning, tag: tag);

  // success
  void s(dynamic message, {dynamic tag}) =>
      _print(className, message, _green, LogLevel.info, tag: tag);

  static void success(Type className, dynamic message, {dynamic tag}) =>
      _print(className, message, _green, LogLevel.info, tag: tag);

  static void _print(
    Type className,
    message,
    int color,
    LogLevel level, {
    required dynamic tag,
  }) {
    String formatted =
        "UI [${level.description}] - <$className>${tag != null ? ' ($tag)' : ''}: $message";

    if (kDebugMode) {
      if (message is Error) {
        formatted += '\nStackTrace:\n${message.stackTrace}';
      }
      print("""\x1B[38;5;${color}m$formatted\x1B[0m""");
    }
  }
}
