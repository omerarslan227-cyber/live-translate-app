import '../config/app_config.dart';
import '../core/app_logger.dart';

class WebRtcConfigService {
  const WebRtcConfigService._();

  static Map<String, dynamic> productionIceConfiguration() {
    final servers = <Map<String, dynamic>>[
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun.cloudflare.com:3478',
        ],
      },
    ];

    _appendTurnServer(
      servers,
      urls: AppConfig.twilioTurnUrls,
      username: AppConfig.twilioTurnUser,
      credential: AppConfig.twilioTurnPassword,
      provider: 'twilio',
    );
    _appendTurnServer(
      servers,
      urls: AppConfig.fallbackTurnUrls,
      username: AppConfig.fallbackTurnUser,
      credential: AppConfig.fallbackTurnPassword,
      provider: 'fallback',
    );

    final policy = AppConfig.forceRelay ? 'relay' : 'all';
    AppLogger.info('webrtc', 'ICE configuration loaded', {
      'environment': AppConfig.environment,
      'iceTransportPolicy': policy,
      'turnServersConfigured': servers.length - 1,
      'forceRelay': AppConfig.forceRelay,
    });

    return {
      'iceServers': servers,
      'iceTransportPolicy': policy,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceCandidatePoolSize': 6,
    };
  }

  static void _appendTurnServer(
    List<Map<String, dynamic>> servers, {
    required String urls,
    required String username,
    required String credential,
    required String provider,
  }) {
    final parsedUrls = AppConfig.splitCsv(urls);
    final hasCredentials = username.trim().isNotEmpty && credential.isNotEmpty;
    if (parsedUrls.isEmpty || !hasCredentials) {
      AppLogger.warn('webrtc', 'TURN server not configured', {
        'provider': provider,
        'hasUrls': parsedUrls.isNotEmpty,
        'hasCredentials': hasCredentials,
      });
      return;
    }

    servers.add({
      'urls': parsedUrls.length == 1 ? parsedUrls.first : parsedUrls,
      'username': username,
      'credential': credential,
    });
  }

  static String candidateType(String? candidate) {
    if (candidate == null || candidate.trim().isEmpty) return 'empty';
    final match = RegExp(r' typ ([a-zA-Z0-9_-]+)').firstMatch(candidate);
    return match?.group(1) ?? 'unknown';
  }
}
