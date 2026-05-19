part of '../main.dart';

class AppColors {
  static const bg = Color(0xFF050816);
  static const card = Color(0xFF0B1224);
  static const cardSoft = Color(0xFF111B34);
  static const border = Color(0xFF1E2B4A);
  static const purple = Color(0xFF8B5CF6);
  static const blue = Color(0xFF4F8CFF);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFFF4D4F);
  static const yellow = Color(0xFFFBBF24);
}

class AppStore {
  static const _historyKey = 'call_history_v1';
  static const _messagesKey = 'message_history_v1';
  static const _profileKey = 'profile_v1';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<ProfileData> loadProfile() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return const ProfileData();
    try {
      return ProfileData.fromJson(jsonDecode(raw));
    } catch (_) {
      return const ProfileData();
    }
  }

  static Future<void> saveProfile(ProfileData profile) async {
    final prefs = await _prefs;
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    triggerAppRefresh();
  }

  static Future<List<CallHistoryEntry>> loadHistory() async {
    final prefs = await _prefs;
    final rawList = prefs.getStringList(_historyKey) ?? <String>[];
    final items = <CallHistoryEntry>[];
    for (final raw in rawList) {
      try {
        items.add(CallHistoryEntry.fromJson(jsonDecode(raw)));
      } catch (_) {}
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static Future<void> addHistory(CallHistoryEntry entry) async {
    final prefs = await _prefs;
    final items = await loadHistory();
    items.removeWhere(
      (e) =>
          e.roomName == entry.roomName &&
          e.privateCode == entry.privateCode &&
          e.timestamp.difference(entry.timestamp).inMinutes.abs() < 2,
    );
    items.insert(0, entry);
    final trimmed = items.take(25).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_historyKey, trimmed);
    triggerAppRefresh();
  }

  static Future<List<StoredMessage>> loadMessages() async {
    final prefs = await _prefs;
    final rawList = prefs.getStringList(_messagesKey) ?? <String>[];
    final items = <StoredMessage>[];
    for (final raw in rawList) {
      try {
        items.add(StoredMessage.fromJson(jsonDecode(raw)));
      } catch (_) {}
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static Future<void> addStoredMessage(StoredMessage message) async {
    final prefs = await _prefs;
    final items = await loadMessages();
    items.insert(0, message);
    final trimmed = items.take(100).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_messagesKey, trimmed);
    triggerAppRefresh();
  }

  static String inviteLink(String roomName, String code) {
    return GrowthService.inviteLink(roomName, code);
  }
}

class ProfileData {
  final String displayName;
  final String about;
  final String preferredSourceLanguage;
  final String preferredTargetLanguage;
  final bool avatarMode;

  const ProfileData({
    this.displayName = '',
    this.about = '',
    this.preferredSourceLanguage = 'Türkçe',
    this.preferredTargetLanguage = 'İngilizce',
    this.avatarMode = false,
  });

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'about': about,
    'preferredSourceLanguage': preferredSourceLanguage,
    'preferredTargetLanguage': preferredTargetLanguage,
    'avatarMode': avatarMode,
  };

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    displayName: (json['displayName'] ?? '').toString(),
    about: (json['about'] ?? '').toString(),
    preferredSourceLanguage: (json['preferredSourceLanguage'] ?? 'Türkçe')
        .toString(),
    preferredTargetLanguage: (json['preferredTargetLanguage'] ?? 'İngilizce')
        .toString(),
    avatarMode: json['avatarMode'] == true,
  );
}

class CallHistoryEntry {
  final String roomName;
  final String privateCode;
  final String sourceLanguage;
  final String targetLanguage;
  final int memberCount;
  final int durationSeconds;
  final DateTime timestamp;

  CallHistoryEntry({
    required this.roomName,
    required this.privateCode,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.memberCount,
    required this.durationSeconds,
    required this.timestamp,
  });

  String get durationLabel {
    final h = (durationSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((durationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get relativeLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün';
    return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}';
  }

  Map<String, dynamic> toJson() => {
    'roomName': roomName,
    'privateCode': privateCode,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'memberCount': memberCount,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CallHistoryEntry.fromJson(Map<String, dynamic> json) =>
      CallHistoryEntry(
        roomName: (json['roomName'] ?? '').toString(),
        privateCode: (json['privateCode'] ?? '').toString(),
        sourceLanguage: (json['sourceLanguage'] ?? 'Türkçe').toString(),
        targetLanguage: (json['targetLanguage'] ?? 'Rusça').toString(),
        memberCount: (json['memberCount'] ?? 1) as int,
        durationSeconds: (json['durationSeconds'] ?? 0) as int,
        timestamp:
            DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class StoredMessage {
  final String roomName;
  final String text;
  final String translatedText;
  final bool isMine;
  final DateTime timestamp;

  StoredMessage({
    required this.roomName,
    required this.text,
    required this.translatedText,
    required this.isMine,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'roomName': roomName,
    'text': text,
    'translatedText': translatedText,
    'isMine': isMine,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StoredMessage.fromJson(Map<String, dynamic> json) => StoredMessage(
    roomName: (json['roomName'] ?? '').toString(),
    text: (json['text'] ?? '').toString(),
    translatedText: (json['translatedText'] ?? '').toString(),
    isMine: json['isMine'] == true,
    timestamp:
        DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
        DateTime.now(),
  );
}
