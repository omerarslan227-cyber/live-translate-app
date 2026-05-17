import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String scope, String message, [Map<String, Object?> data = const {}]) {
    _write('INFO', scope, message, data);
  }

  static void warn(String scope, String message, [Map<String, Object?> data = const {}]) {
    _write('WARN', scope, message, data);
  }

  static void error(
    String scope,
    String message, [
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _write('ERROR', scope, message, {
      ...data,
      if (error != null) 'error': error.toString(),
    });
    if (!kReleaseMode && stackTrace != null) {
      debugPrintStack(label: '[BridgeCall][$scope]', stackTrace: stackTrace);
    }
  }

  static void _write(
    String level,
    String scope,
    String message,
    Map<String, Object?> data,
  ) {
    if (kReleaseMode && level == 'INFO') return;
    final payload = data.isEmpty ? '' : ' ${jsonEncode(data)}';
    debugPrint('[BridgeCall][$level][$scope] $message$payload');
  }
}
