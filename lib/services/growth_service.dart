class GrowthService {
  static String inviteLink(String roomName, String code) {
    return 'https://bridgecall.app/join?room=$roomName&code=$code';
  }

  static String roomInviteMessage(String roomName, String code) {
    return 'BridgeCall odama katıl: ${inviteLink(roomName, code)}';
  }

  static String transcriptShareMessage({
    required String original,
    required String translated,
  }) {
    final buffer = StringBuffer('BridgeCall ile konuştum');
    if (original.trim().isNotEmpty) {
      buffer.writeln('\n\nOrijinal: ${original.trim()}');
    }
    if (translated.trim().isNotEmpty) {
      buffer.writeln('Çeviri: ${translated.trim()}');
    }
    buffer.writeln('\nCanlı çeviri için BridgeCall');
    return buffer.toString();
  }

  static String referralMessage(String code) {
    return 'BridgeCall davet kodum: $code. Arkadaşını davet et, ikiniz de 1 hafta Pro kazanın.';
  }
}
