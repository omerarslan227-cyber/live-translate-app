class ConfigService {
  const ConfigService._();

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const wsUrl = String.fromEnvironment('WS_URL');
  static const backendHttpUrl = String.fromEnvironment('BACKEND_HTTP_URL');

  static const twilioTurnUrls = String.fromEnvironment('TWILIO_TURN_URLS');
  static const twilioTurnUser = String.fromEnvironment('TWILIO_TURN_USERNAME');
  static const twilioTurnPassword = String.fromEnvironment(
    'TWILIO_TURN_PASSWORD',
  );

  static const fallbackTurnUrls = String.fromEnvironment('TURN_URLS');
  static const fallbackTurnUser = String.fromEnvironment('TURN_USERNAME');
  static const fallbackTurnPassword = String.fromEnvironment('TURN_PASSWORD');

  static const forceRelay = bool.fromEnvironment(
    'WEBRTC_FORCE_RELAY',
    defaultValue: false,
  );

  static bool get isBackendConfigured => wsUrl.trim().isNotEmpty;

  static Uri? wsEndpoint(String path) {
    final base = wsUrl.trim();
    if (base.isEmpty) return null;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}$normalizedPath');
  }

  static Uri? get healthUri {
    final httpBase = backendHttpUrl.trim();
    if (httpBase.isNotEmpty) {
      return Uri.parse('${httpBase.replaceAll(RegExp(r'/+$'), '')}/health');
    }

    final wsBase = wsUrl.trim();
    if (wsBase.isEmpty) return null;
    final httpUrl = wsBase
        .replaceFirst(RegExp(r'^wss://'), 'https://')
        .replaceFirst(RegExp(r'^ws://'), 'http://');
    return Uri.parse('${httpUrl.replaceAll(RegExp(r'/+$'), '')}/health');
  }

  static List<String> splitCsv(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

typedef AppConfig = ConfigService;
