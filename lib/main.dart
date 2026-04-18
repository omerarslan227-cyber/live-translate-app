import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String baseWsUrl =
    'wss://live-translate-backed-production.up.railway.app';

final ValueNotifier<int> appRefresh = ValueNotifier<int>(0);

void triggerAppRefresh() => appRefresh.value++;

void main() {
  runApp(const LiveTranslateApp());
}

class LiveTranslateApp extends StatelessWidget {
  const LiveTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Translate',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050816),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF4F8CFF),
          surface: Color(0xFF0B1224),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

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

String languageFlag(String language) {
  switch (language) {
    case 'Türkçe':
      return '🇹🇷';
    case 'Rusça':
      return '🇷🇺';
    case 'Ukraynaca':
      return '🇺🇦';
    case 'İngilizce':
      return '🇬🇧';
    case 'Gürcüce':
      return '🇬🇪';
    default:
      return '🌐';
  }
}


class AppStore {
  static const _historyKey = 'call_history_v1';
  static const _messagesKey = 'message_history_v1';
  static const _profileKey = 'profile_v1';

  static Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

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
    items.removeWhere((e) =>
        e.roomName == entry.roomName &&
        e.privateCode == entry.privateCode &&
        e.timestamp.difference(entry.timestamp).inMinutes.abs() < 2);
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
    return 'https://bridgecall.app/join?room=$roomName&code=$code';
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
    this.preferredTargetLanguage = 'Rusça',
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
        preferredSourceLanguage: (json['preferredSourceLanguage'] ?? 'Türkçe').toString(),
        preferredTargetLanguage: (json['preferredTargetLanguage'] ?? 'Rusça').toString(),
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

  factory CallHistoryEntry.fromJson(Map<String, dynamic> json) => CallHistoryEntry(
        roomName: (json['roomName'] ?? '').toString(),
        privateCode: (json['privateCode'] ?? '').toString(),
        sourceLanguage: (json['sourceLanguage'] ?? 'Türkçe').toString(),
        targetLanguage: (json['targetLanguage'] ?? 'Rusça').toString(),
        memberCount: (json['memberCount'] ?? 1) as int,
        durationSeconds: (json['durationSeconds'] ?? 0) as int,
        timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now(),
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
        timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now(),
      );
}


class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const MessagesScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, -8)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 76,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white.withOpacity(0.08),
            surfaceTintColor: Colors.transparent,
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: true,
                  label: Text('3'),
                  child: Icon(Icons.chat_bubble_outline_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: true,
                  label: Text('3'),
                  child: Icon(Icons.chat_bubble_rounded),
                ),
                label: 'Mesajlar',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_time_rounded),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Geçmiş',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appRefresh,
      builder: (context, _, __) {
        return FutureBuilder<_HomeData>(
          future: _loadHomeData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _HomeData();
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040816), Color(0xFF061227), Color(0xFF090F1D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [AppColors.purple, Color(0xFF6D5BFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.translate_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Live Translate',
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: const Icon(Icons.settings_outlined, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _StatusStrip(profileName: data.profile.displayName),
                    const SizedBox(height: 14),
                    _LastRoomCard(lastHistory: data.lastHistory),
                    const SizedBox(height: 16),
                    _ActionButton(
                      title: 'Oda Oluştur',
                      subtitle: 'Yeni bir oda oluştur ve davet et',
                      icon: Icons.add_rounded,
                      gradient: const [Color(0xFF9D6BFF), Color(0xFF6C49E8)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreateRoomScreen(profile: data.profile)),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ActionButton(
                      title: 'Odaya Katıl',
                      subtitle: 'Kod ile mevcut odaya katıl',
                      icon: Icons.login_rounded,
                      gradient: const [Color(0xFF4B7DFF), Color(0xFF355BEF)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => JoinRoomScreen(profile: data.profile)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const _DemoCard(),
                    const SizedBox(height: 16),
                    _RecentConversationsCard(history: data.history),
                    const SizedBox(height: 16),
                    _InviteCard(lastHistory: data.lastHistory),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<_HomeData> _loadHomeData() async {
    final history = await AppStore.loadHistory();
    final profile = await AppStore.loadProfile();
    return _HomeData(
      history: history,
      lastHistory: history.isNotEmpty ? history.first : null,
      profile: profile,
    );
  }
}

class _HomeData {

  final List<CallHistoryEntry> history;
  final CallHistoryEntry? lastHistory;
  final ProfileData profile;

  const _HomeData({
    this.history = const [],
    this.lastHistory,
    this.profile = const ProfileData(),
  });
}


class _StatusStrip extends StatelessWidget {
  final String profileName;

  const _StatusStrip({required this.profileName});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.circle, color: AppColors.green, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '38 kişi aktif',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              profileName.isEmpty ? '🔥 Popüler: Türkçe ↔ Rusça' : '🔥 $profileName için popüler: Türkçe ↔ Rusça',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }
}

class _LastRoomCard extends StatelessWidget {
  final CallHistoryEntry? lastHistory;

  const _LastRoomCard({required this.lastHistory});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Son oda', style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 10),
                Text(
                  lastHistory?.roomName ?? 'oda1',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  lastHistory == null
                      ? '2 kişi • 00:12:36'
                      : '${lastHistory!.memberCount} kişi • ${lastHistory!.durationLabel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: lastHistory == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JoinRoomScreen(
                          initialRoomName: lastHistory!.roomName,
                          initialCode: lastHistory!.privateCode,
                        ),
                      ),
                    );
                  },
            child: Text(lastHistory == null ? 'Hazır Değil' : 'Tekrar Bağlan'),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                'Canlı Çeviri Denemesi',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8F7CFF)),
              ),
              Spacer(),
              Text('● Canlı', style: TextStyle(color: AppColors.green)),
            ],
          ),
          SizedBox(height: 14),
          _DemoLine(from: 'EN', to: 'TR', source: 'Hello, how are you?', target: 'Merhaba, nasılsın?'),
          SizedBox(height: 12),
          _DemoLine(from: 'EN', to: 'TR', source: 'Where are you from?', target: 'Nerelisin?'),
        ],
      ),
    );
  }
}

class _DemoLine extends StatelessWidget {
  final String from;
  final String to;
  final String source;
  final String target;

  const _DemoLine({
    required this.from,
    required this.to,
    required this.source,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Roboto', color: Colors.white),
              children: [
                TextSpan(text: '$from   ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                TextSpan(text: source, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const TextSpan(text: '\n'),
                TextSpan(text: '$to   ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                TextSpan(text: target, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.graphic_eq_rounded, color: AppColors.purple, size: 34),
      ],
    );
  }
}

class _RecentConversationsCard extends StatelessWidget {
  final List<CallHistoryEntry> history;

  const _RecentConversationsCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final items = history.isEmpty
        ? [
            CallHistoryEntry(
              roomName: 'Ahmet',
              privateCode: '123456',
              sourceLanguage: 'Türkçe',
              targetLanguage: 'Rusça',
              memberCount: 2,
              durationSeconds: 870,
              timestamp: DateTime.now().subtract(const Duration(hours: 7)),
            ),
            CallHistoryEntry(
              roomName: 'Rusça Pratik',
              privateCode: '654321',
              sourceLanguage: 'Türkçe',
              targetLanguage: 'Rusça',
              memberCount: 2,
              durationSeconds: 502,
              timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
            ),
          ]
        : history.take(3).toList();

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: const [
              Text('Son Konuşmalar', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              Spacer(),
              Text('Tümünü Gör', style: TextStyle(color: Color(0xFF8F7CFF), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ConversationTile(entry: entry),
              )),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final CallHistoryEntry entry;

  const _ConversationTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.roomName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 3),
                Text(
                  '${entry.memberCount} kişi • ${entry.durationLabel}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.sourceLanguage} ↔ ${entry.targetLanguage}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF684EFF)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JoinRoomScreen(
                    initialRoomName: entry.roomName,
                    initialCode: entry.privateCode,
                  ),
                ),
              );
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final CallHistoryEntry? lastHistory;

  const _InviteCard({required this.lastHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1530), Color(0xFF26184B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arkadaşını Davet Et', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Davet linkini paylaş, birlikte konuşun!', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () async {
              if (lastHistory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Önce bir oda oluştur veya bir odaya katıl.')),
                );
                return;
              }
              final link = AppStore.inviteLink(lastHistory!.roomName, lastHistory!.privateCode);
              await Share.share('BridgeCall odama katıl: $link');
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF7C7C), size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {

  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appRefresh,
      builder: (context, _, __) {
        return FutureBuilder<List<StoredMessage>>(
          future: AppStore.loadMessages(),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? const <StoredMessage>[];
            return Scaffold(
              appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Mesajlar')),
              body: messages.isEmpty
                  ? const Center(child: Text('Henüz kayıtlı mesaj yok'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = messages[index];
                        return _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(item.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  Text(item.isMine ? 'Ben' : 'Karşı', style: const TextStyle(color: Colors.white60)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(item.text),
                              if (item.translatedText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(item.translatedText, style: const TextStyle(color: Colors.white70)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appRefresh,
      builder: (context, _, __) {
        return FutureBuilder<List<CallHistoryEntry>>(
          future: AppStore.loadHistory(),
          builder: (context, snapshot) {
            final history = snapshot.data ?? const <CallHistoryEntry>[];
            return Scaffold(
              appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Geçmiş')),
              body: history.isEmpty
                  ? const Center(child: Text('Henüz geçmiş yok'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(item.roomName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ),
                                  Text(item.relativeLabel, style: const TextStyle(color: Colors.white60)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${item.sourceLanguage} ↔ ${item.targetLanguage}'),
                              const SizedBox(height: 6),
                              Text('Süre: ${item.durationLabel} • Katılımcı: ${item.memberCount} • Kod: ${item.privateCode}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.purple)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JoinRoomScreen(
                                          initialRoomName: item.roomName,
                                          initialCode: item.privateCode,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tekrar Katıl'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  String _source = 'Türkçe';
  String _target = 'Rusça';
  bool _avatarMode = false;
  bool _loading = true;

  final List<String> languages = const ['Türkçe', 'Rusça', 'Ukraynaca', 'İngilizce', 'Gürcüce'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await AppStore.loadProfile();
    _nameController.text = profile.displayName;
    _aboutController.text = profile.about;
    _source = profile.preferredSourceLanguage;
    _target = profile.preferredTargetLanguage;
    _avatarMode = profile.avatarMode;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final profile = ProfileData(
      displayName: _nameController.text.trim(),
      about: _aboutController.text.trim(),
      preferredSourceLanguage: _source,
      preferredTargetLanguage: _target,
      avatarMode: _avatarMode,
    );
    await AppStore.saveProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil kaydedildi')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profil Bilgileri', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _AppTextField(controller: _nameController, label: 'Görünen ad'),
                const SizedBox(height: 14),
                _AppTextField(controller: _aboutController, label: 'Hakkında', hint: 'Kısa bir açıklama yaz'),
                const SizedBox(height: 14),
                _LanguageDropdown(
                  value: _source,
                  label: 'Tercih edilen kaynak dil',
                  items: languages,
                  onChanged: (v) => setState(() => _source = v ?? 'Türkçe'),
                ),
                const SizedBox(height: 14),
                _LanguageDropdown(
                  value: _target,
                  label: 'Tercih edilen hedef dil',
                  items: languages,
                  onChanged: (v) => setState(() => _target = v ?? 'Rusça'),
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Avatar modu'),
                  subtitle: const Text('Şimdilik görünüm ayarı olarak saklanır'),
                  value: _avatarMode,
                  onChanged: (value) => setState(() => _avatarMode = value),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.purple, minimumSize: const Size.fromHeight(54)),
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Profili Kaydet'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateRoomScreen extends StatefulWidget {
  final ProfileData? profile;

  const CreateRoomScreen({super.key, this.profile});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController roomController = TextEditingController(text: 'oda1');
  final TextEditingController codeController = TextEditingController();

  String sourceLanguageName = 'Türkçe';
  String targetLanguageName = 'Rusça';
  int selectedCapacity = 2;
  bool showAdvanced = false;

  final List<String> languages = const ['Türkçe', 'Rusça', 'Ukraynaca', 'İngilizce', 'Gürcüce'];
  final List<int> capacities = const [2, 4, 6, 8];

  @override
  void initState() {
    super.initState();
    codeController.text = _generateRoomCode();
    final profile = widget.profile;
    if (profile != null) {
      sourceLanguageName = profile.preferredSourceLanguage;
      targetLanguageName = profile.preferredTargetLanguage;
    }
  }

  String _generateRoomCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return now.substring(now.length - 6);
  }

  void _openCall() {
    final roomName = roomController.text.trim().isEmpty ? 'oda1' : roomController.text.trim();
    final code = codeController.text.trim().isEmpty ? _generateRoomCode() : codeController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomName: roomName,
          privateCode: code,
          sourceLanguageName: sourceLanguageName,
          targetLanguageName: targetLanguageName,
          roomCapacity: selectedCapacity,
          isOwner: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    roomController.dispose();
    codeController.dispose();
    super.dispose();
  }

  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Oda Oluştur'),
      centerTitle: true,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C153A), Color(0xFF24164B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.purple, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hızlı Başlat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('En popüler ayarlarla hemen odayı oluştur', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF7C61FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _openCall,
                child: const Text('Hızlı Başlat'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ayarlar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LanguageDropdown(
                      value: sourceLanguageName,
                      label: 'Dil seçimi',
                      items: languages,
                      onChanged: (v) => setState(() => sourceLanguageName = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white70),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LanguageDropdown(
                      value: targetLanguageName,
                      label: '',
                      items: languages,
                      onChanged: (v) => setState(() => targetLanguageName = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: selectedCapacity,
                decoration: _inputDecoration('Oda kapasitesi'),
                dropdownColor: AppColors.card,
                items: capacities.map((e) => DropdownMenuItem(value: e, child: Text('$e kişi'))).toList(),
                onChanged: (value) => setState(() => selectedCapacity = value ?? 2),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: 'Özel oda (kod ile giriş)',
                decoration: _inputDecoration('Oda tipi'),
                dropdownColor: AppColors.card,
                items: const [
                  DropdownMenuItem(
                    value: 'Özel oda (kod ile giriş)',
                    child: Text('Özel oda (kod ile giriş)'),
                  ),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => showAdvanced = !showAdvanced),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Gelişmiş Ayarlar')),
                      Icon(showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    ],
                  ),
                ),
              ),
              if (showAdvanced) ...[
                const SizedBox(height: 14),
                _AppTextField(controller: roomController, label: 'Oda adı'),
                const SizedBox(height: 14),
                _AppTextField(controller: codeController, label: 'Özel oda kodu'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => codeController.text = _generateRoomCode()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Yeni Kod Oluştur'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: AppColors.purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: _openCall,
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Odayı Başlat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              final roomLink = AppStore.inviteLink(roomController.text.trim(), codeController.text.trim());
              await Share.share('BridgeCall odama katıl: $roomLink');
            },
            icon: const Icon(Icons.link_rounded),
            label: const Text('Link paylaş'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _BottomFeature(
                icon: Icons.schedule_rounded,
                title: 'Günlük Hak',
                subtitle: '10 dk / 10 dk',
                color: Color(0xFFFFC83D),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _BottomFeature(
                icon: Icons.shield_outlined,
                title: 'Güvenli',
                subtitle: 'Uçtan uca şifreleme',
                color: AppColors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _BottomFeature(
                icon: Icons.hd_rounded,
                title: 'Yüksek Kalite',
                subtitle: 'HD ses & video',
                color: AppColors.purple,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

}

class JoinRoomScreen extends StatefulWidget {
  final String? initialRoomName;
  final String? initialCode;
  final ProfileData? profile;

  const JoinRoomScreen({super.key, this.initialRoomName, this.initialCode, this.profile});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController roomController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  String sourceLanguageName = 'Türkçe';
  String targetLanguageName = 'Rusça';

  @override
  void initState() {
    super.initState();
    roomController.text = widget.initialRoomName ?? 'oda1';
    codeController.text = widget.initialCode ?? '';
    final profile = widget.profile;
    if (profile != null) {
      sourceLanguageName = profile.preferredSourceLanguage;
      targetLanguageName = profile.preferredTargetLanguage;
    }
  }

  @override
  void dispose() {
    roomController.dispose();
    codeController.dispose();
    super.dispose();
  }

  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Odaya Katıl'),
      centerTitle: true,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        _GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AppTextField(controller: codeController, label: 'Oda kodu', hint: '6 haneli oda kodunu gir'),
              const SizedBox(height: 14),
              _AppTextField(controller: roomController, label: 'Oda adı'),
              const SizedBox(height: 14),
              _LanguageDropdown(
                value: sourceLanguageName,
                label: 'Benim konuşma dilim',
                items: const ['Türkçe', 'Rusça', 'Ukraynaca', 'İngilizce', 'Gürcüce'],
                onChanged: (value) => setState(() => sourceLanguageName = value ?? 'Türkçe'),
              ),
              const SizedBox(height: 14),
              _LanguageDropdown(
                value: targetLanguageName,
                label: 'Dinlemek istediğim dil',
                items: const ['Türkçe', 'Rusça', 'Ukraynaca', 'İngilizce', 'Gürcüce'],
                onChanged: (value) => setState(() => targetLanguageName = value ?? 'Rusça'),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallScreen(
                        roomName: roomController.text.trim(),
                        privateCode: codeController.text.trim(),
                        sourceLanguageName: sourceLanguageName,
                        targetLanguageName: targetLanguageName,
                        roomCapacity: 2,
                        isOwner: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Odaya Katıl', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: roomController.text.trim()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oda adı kopyalandı')));
                    }
                  },
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Kod nasıl alınır?'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _BottomFeature(
                icon: Icons.schedule_rounded,
                title: 'Günlük Hak',
                subtitle: '10 dk / 10 dk',
                color: Color(0xFFFFC83D),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _BottomFeature(
                icon: Icons.lock_outline_rounded,
                title: 'Güvenli',
                subtitle: 'Uçtan uca şifreleme',
                color: AppColors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _BottomFeature(
                icon: Icons.hd_rounded,
                title: 'Yüksek Kalite',
                subtitle: 'HD ses & video',
                color: AppColors.purple,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

}

class CallScreen extends StatefulWidget {
  final String roomName;
  final String privateCode;
  final String sourceLanguageName;
  final String targetLanguageName;
  final int roomCapacity;
  final bool isOwner;

  const CallScreen({
    super.key,
    required this.roomName,
    required this.privateCode,
    required this.sourceLanguageName,
    required this.targetLanguageName,
    required this.roomCapacity,
    required this.isOwner,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController _chatController = TextEditingController();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  WebSocketChannel? _signalChannel;
  WebSocketChannel? _translateChannel;

  bool micOn = true;
  bool camOn = true;
  bool subtitlesOn = true;
  bool cameraStarted = false;
  bool isRecording = false;
  bool _showChat = false;
  bool _isConnecting = false;
  bool _historySaved = false;

  String subtitleText = 'Canlı altyazı burada görünecek';
  String translatedText = 'Çeviri burada görünecek';
  String statusText = 'Hazırlanıyor...';
  String? myClientId;
  int memberCount = 1;

  late String sourceLanguageName;
  late String targetLanguageName;
  DateTime _callStart = DateTime.now();

  final List<_ChatMessage> _messages = [];

  String? _reactionEmoji;
  Timer? _reactionTimer;
  Timer? _durationTimer;

  final Map<String, String> sourceLanguages = const {
    'Türkçe': 'TR',
    'Rusça': 'RU',
    'Ukraynaca': 'UK',
    'İngilizce': 'EN',
    'Gürcüce': 'KA',
  };

  final Map<String, String> targetLanguages = const {
    'Türkçe': 'TR',
    'Rusça': 'RU',
    'Ukraynaca': 'UK',
    'İngilizce': 'EN-US',
    'Gürcüce': 'KA',
  };

  final Map<String, dynamic> _iceConfig = const {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  @override
  void initState() {
    super.initState();
    sourceLanguageName = widget.sourceLanguageName;
    targetLanguageName = widget.targetLanguageName;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _initAll();
  }

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _recorder.openRecorder();
    await _openCamera();
    await _joinRoom();
    if (mounted) {
      setState(() {
        statusText = widget.isOwner ? 'Oda hazır, katılımcı bekleniyor' : 'Bağlantı kuruluyor';
      });
    }
  }

  Future<void> _openCamera() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'googEchoCancellation': true,
          'googNoiseSuppression': true,
          'googAutoGainControl': true,
          'googHighpassFilter': true,
        },
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 720},
          'height': {'ideal': 1280},
          'frameRate': {'ideal': 24},
        },
      });
      _localStream = stream;
      _localRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          cameraStarted = true;
          statusText = 'Kamera ve ses hazır';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusText = 'Kamera veya mikrofon izni gerekli';
        });
      }
    }
  }

  Future<String> _tempWavPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/temp_audio.wav';
  }

  Future<void> _createPeerConnection() async {
    _peerConnection ??= await createPeerConnection(_iceConfig);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        if (mounted) {
          setState(() {
            statusText = 'Karşı taraf bağlandı';
          });
        }
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _sendSignal({
          'type': 'candidate',
          'room': widget.roomName,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (mounted) {
        setState(() {
          statusText = state.toString().contains('RTCPeerConnectionStateConnected') ? 'Karşı taraf bağlandı' : 'Bağlantı güncelleniyor';
        });
      }
    };
  }

  Future<void> _connectSignalSocket() async {
    if (_signalChannel != null) return;

    _signalChannel = WebSocketChannel.connect(Uri.parse('$baseWsUrl/signal'));

    _signalChannel!.stream.listen(
      (message) async => _handleSignal(message),
      onError: (error) {
        if (mounted) setState(() => statusText = 'Signal hatası: $error');
      },
      onDone: () {
        if (mounted) setState(() => statusText = 'Signal bağlantısı kapandı');
      },
    );
  }

  Future<void> _joinRoom() async {
    if (_isConnecting) return;
    _isConnecting = true;

    if (!cameraStarted) {
      await _openCamera();
    }

    await _connectSignalSocket();
    await _createPeerConnection();

    if (widget.isOwner) {
      _sendSignal({
        'type': 'create_room',
        'room': widget.roomName,
        'capacity': widget.roomCapacity,
        'privateCode': widget.privateCode,
      });
    } else {
      _sendSignal({
        'type': 'request_join',
        'room': widget.roomName,
        'privateCode': widget.privateCode,
      });
    }

    _isConnecting = false;
  }

  void _connectTranslateSocket() {
    if (_translateChannel != null) return;

    _translateChannel = WebSocketChannel.connect(Uri.parse('$baseWsUrl/translate'));
    _translateChannel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          if (mounted && data['translated'] != null) {
            setState(() {
              subtitleText = data['original']?.toString() ?? subtitleText;
              translatedText = data['translated']?.toString() ?? translatedText;
            });
          }
          if (mounted && data['error'] != null) {
            setState(() => statusText = 'Çeviri hatası: ${data['error']}');
          }
        } catch (e) {
          if (mounted) setState(() => statusText = 'Çeviri veri hatası: $e');
        }
      },
      onError: (error) {
        if (mounted) setState(() => statusText = 'Çeviri soketi hatası: $error');
      },
    );
  }

  Future<void> _startSubtitleRecording() async {
    if (isRecording || !subtitlesOn || !micOn) return;
    _connectTranslateSocket();
    isRecording = true;
    if (mounted) setState(() {});

    while (isRecording && subtitlesOn && micOn) {
      try {
        final path = await _tempWavPath();
        await _recorder.startRecorder(
          toFile: path,
          codec: Codec.pcm16WAV,
          numChannels: 1,
          sampleRate: 16000,
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        final savedPath = await _recorder.stopRecorder();
        if (savedPath != null) {
          final file = File(savedPath);
          if (await file.exists()) {
            final fileBytes = await file.readAsBytes();
            _translateChannel?.sink.add(jsonEncode({
              'audio': base64Encode(fileBytes),
              'sourceLang': sourceLanguages[sourceLanguageName],
              'targetLang': targetLanguages[targetLanguageName],
            }));
          }
        }
      } catch (e) {
        if (mounted) setState(() => statusText = 'Mikrofon erişimi kontrol edilmeli');
        isRecording = false;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _stopSubtitleRecording() async {
    isRecording = false;
    try {
      await _recorder.stopRecorder();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _startCall() async {
    if (_peerConnection == null) {
      await _createPeerConnection();
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignal({
      'type': 'offer',
      'room': widget.roomName,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });

    if (mounted) setState(() => statusText = 'Arama isteği gönderildi');
  }

  Future<void> _handleSignal(dynamic rawMessage) async {
    final data = jsonDecode(rawMessage as String);
    final type = data['type'];

    if (type == 'welcome') {
      if (mounted) setState(() => myClientId = data['clientId']?.toString());
      return;
    }

    if (data['room'] != null && data['room'] != widget.roomName) return;

    switch (type) {
      case 'error':
        if (mounted) setState(() => statusText = data['message']?.toString() ?? 'Bilinmeyen hata');
        return;
      case 'room_created':
        if (mounted) {
          setState(() {
            memberCount = data['memberCount'] ?? 1;
            statusText = 'Oda oluşturuldu. Kod: ${widget.privateCode}';
          });
        }
        return;
      case 'join_request':
        final requesterId = data['requesterId'];
        _sendSignal({
          'type': 'join_decision',
          'room': widget.roomName,
          'requesterId': requesterId,
          'accept': true,
        });
        if (mounted) setState(() => statusText = 'Katılım isteği otomatik kabul edildi');
        return;
      case 'join_accepted':
        if (mounted) {
          setState(() {
            memberCount = data['memberCount'] ?? 2;
            statusText = 'Odaya giriş onaylandı';
          });
        }
        return;
      case 'join_rejected':
        if (mounted) setState(() => statusText = 'Odaya giriş reddedildi');
        return;
      case 'member_joined':
        if (mounted) {
          setState(() {
            memberCount += 1;
            statusText = 'Yeni bir kullanıcı katıldı';
          });
        }
        if (widget.isOwner) {
          await _startCall();
        }
        return;
      case 'member_left':
        if (mounted) {
          setState(() {
            memberCount = memberCount > 1 ? memberCount - 1 : 1;
            statusText = 'Bir kullanıcı odadan çıktı';
          });
        }
        return;
      case 'room_closed':
        if (mounted) {
          setState(() => statusText = 'Oda sahibi çağrıyı kapattı');
        }
        await _saveHistoryIfNeeded();
        if (mounted) Navigator.pop(context);
        return;
      case 'left_room':
        if (mounted) setState(() => statusText = 'Odadan çıkıldı');
        return;
      case 'chat_message':
        final incoming = data['text']?.toString() ?? '';
        final translated = data['translatedText']?.toString() ?? '';
        final senderId = data['senderId']?.toString();
        final mine = senderId != null && senderId == myClientId;
        if (incoming.isNotEmpty && mounted) {
          final message = _ChatMessage(text: incoming, translatedText: translated, isMine: mine);
          setState(() {
            _messages.add(message);
          });
          await AppStore.addStoredMessage(StoredMessage(
            roomName: widget.roomName,
            text: incoming,
            translatedText: translated,
            isMine: mine,
            timestamp: DateTime.now(),
          ));
        }
        return;
      case 'reaction':
        final emoji = data['emoji']?.toString();
        if (emoji != null && mounted) {
          setState(() => _reactionEmoji = emoji);
          _reactionTimer?.cancel();
          _reactionTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _reactionEmoji = null);
          });
        }
        return;
    }

    if (_peerConnection == null) return;

    if (type == 'offer') {
      final desc = RTCSessionDescription(data['sdp']?.toString(), data['sdpType']?.toString());
      await _peerConnection!.setRemoteDescription(desc);
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _sendSignal({
        'type': 'answer',
        'room': widget.roomName,
        'sdp': answer.sdp,
        'sdpType': answer.type,
      });
      if (mounted) setState(() => statusText = 'Gelen arama kabul edildi');
    } else if (type == 'answer') {
      final desc = RTCSessionDescription(data['sdp']?.toString(), data['sdpType']?.toString());
      await _peerConnection!.setRemoteDescription(desc);
      if (mounted) setState(() => statusText = 'Bağlantı tamamlandı');
    } else if (type == 'candidate') {
      final c = data['candidate'];
      if (c != null) {
        await _peerConnection!.addCandidate(
          RTCIceCandidate(c['candidate']?.toString(), c['sdpMid']?.toString(), c['sdpMLineIndex'] as int?),
        );
      }
    }
  }

  void _sendSignal(Map<String, dynamic> message) {
    _signalChannel?.sink.add(jsonEncode(message));
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    _sendSignal({
      'type': 'chat_message',
      'room': widget.roomName,
      'text': text,
      'sourceLang': sourceLanguages[sourceLanguageName],
      'targetLang': targetLanguages[targetLanguageName],
    });
  }

  void _sendReaction(String emoji) {
    setState(() => _reactionEmoji = emoji);
    _sendSignal({'type': 'reaction', 'room': widget.roomName, 'emoji': emoji});
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _reactionEmoji = null);
    });
  }

  Future<void> _toggleMic() async {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !track.enabled;
      micOn = track.enabled;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !track.enabled;
      camOn = track.enabled;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveHistoryIfNeeded() async {
    if (_historySaved) return;
    _historySaved = true;
    await AppStore.addHistory(
      CallHistoryEntry(
        roomName: widget.roomName,
        privateCode: widget.privateCode,
        sourceLanguage: sourceLanguageName,
        targetLanguage: targetLanguageName,
        memberCount: memberCount,
        durationSeconds: DateTime.now().difference(_callStart).inSeconds,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _hangUp() async {
    try {
      _sendSignal({'type': 'leave_room'});
    } catch (_) {}

    await _saveHistoryIfNeeded();
    await _stopSubtitleRecording();
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteRenderer.srcObject = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;
    _localRenderer.srcObject = null;

    await _signalChannel?.sink.close();
    _signalChannel = null;
    await _translateChannel?.sink.close();
    _translateChannel = null;

    if (mounted) Navigator.pop(context);
  }

  String get _callDuration {
    final diff = DateTime.now().difference(_callStart);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }


  String get _cleanStatusText {
    final lower = statusText.toLowerCase();
    if (lower.contains('authorization failure') || lower.contains('forbidden') || lower.contains('auth_key')) {
      return 'Çeviri servisine bağlanılamadı';
    }
    if (lower.contains('kamera') || lower.contains('mikrofon')) return 'Kamera ve mikrofon izinlerini kontrol et';
    if (lower.contains('signal')) return 'Bağlantı yeniden kuruluyor';
    if (lower.contains('kayıt')) return 'Ses kaydı başlatılamadı';
    return statusText;
  }

  String get _statusPillText {
    if (isRecording) return 'Canlı çeviri aktif';
    if (_remoteRenderer.srcObject != null) return 'Karşı taraf bağlı';
    if (widget.isOwner) return 'Katılımcı bekleniyor';
    return 'Bağlanıyor';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _reactionTimer?.cancel();
    _saveHistoryIfNeeded();
    _stopSubtitleRecording();
    _signalChannel?.sink.close();
    _translateChannel?.sink.close();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _chatController.dispose();
    _recorder.closeRecorder();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final remoteConnected = _remoteRenderer.srcObject != null;
    final bottomInset = media.padding.bottom;

    final topBarHeight = 58.0;
    final videoHeight = size.height * 0.36;
    final subtitleHeight = size.height * 0.21;
    final codeHeight = 52.0;
    final waveHeight = 38.0;
    final controlsHeight = 116.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040714), Color(0xFF071126), Color(0xFF080C19)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  SizedBox(height: topBarHeight, child: _buildCallTopBar()),
                  const SizedBox(height: 14),
                  SizedBox(height: videoHeight, child: _buildRemoteVideoCard(videoHeight, remoteConnected)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SizedBox(height: subtitleHeight, child: _buildSubtitleCard())),
                      const SizedBox(width: 12),
                      _buildReactionRail(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: codeHeight, child: _buildRoomCodeChip()),
                  const SizedBox(height: 14),
                  SizedBox(height: waveHeight, child: const _WaveBar()),
                  const SizedBox(height: 8),
                  Text(
                    isRecording ? 'Sen konuşuyorsun...' : _cleanStatusText,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(height: controlsHeight, child: _buildControlsCard()),
                  SizedBox(height: bottomInset > 0 ? 8 : 14),
                ],
              ),
            ),
          ),
          if (_reactionEmoji != null)
            Positioned(
              right: 18,
              top: 92,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(_reactionEmoji!, style: const TextStyle(fontSize: 30)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openChatSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.48,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _chatPanel(),
          ),
        );
      },
    );
  }

  
Widget _buildCallTopBar() {
  return Row(
    children: [
      InkWell(
        onTap: _hangUp,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(_callDuration, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _TopRoundButton(icon: Icons.groups_rounded, label: '$memberCount'),
      const SizedBox(width: 8),
      _TopRoundButton(
        icon: Icons.chat_bubble_outline_rounded,
        badgeText: _messages.isEmpty ? null : '${_messages.length}',
        onTap: _openChatSheet,
      ),
      const SizedBox(width: 8),
      _TopRoundButton(
        icon: Icons.more_horiz_rounded,
        onTap: () async {
          final link = AppStore.inviteLink(widget.roomName, widget.privateCode);
          await Share.share('BridgeCall odama katıl: $link');
        },
      ),
    ],
  );
}


  Widget _buildRemoteVideoCard(double height, bool remoteConnected) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 30)],
            ),
            clipBehavior: Clip.antiAlias,
            child: remoteConnected
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF171B2D), Color(0xFF10192F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline_rounded, size: 38, color: Colors.white30),
                          ),
                          const SizedBox(height: 12),
                          const Text('Karşı taraf bekleniyor', style: TextStyle(color: Colors.white70, fontSize: 17)),
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              width: 108,
              height: 148,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 24)],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: cameraStarted
                        ? RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : Container(color: Colors.black45),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Siz', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _subtitleRow('$sourceLanguageName (Sen)', subtitleText, AppColors.purple)),
          Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 1, color: Colors.white.withOpacity(0.08)),
          Expanded(child: _subtitleRow('$targetLanguageName (Karşı taraf)', translatedText, AppColors.blue)),
        ],
      ),
    );
  }

  Widget _subtitleRow(String title, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, height: 1.28, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(Icons.graphic_eq_rounded, color: color, size: 24),
        ),
      ],
    );
  }

  Widget _buildReactionRail() {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in ['👍', '😍', '😂', '😮', '👏'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _sendReaction(emoji),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomCodeChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Oda Kodu: ${widget.privateCode}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: widget.privateCode));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oda kodu kopyalandı')),
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Kopyala', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 16, color: AppColors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
Widget _buildControlsCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.28),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Row(
      children: [
        Expanded(
          child: _controlItem(
            icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: 'Mikrofon',
            color: micOn ? AppColors.green : Colors.white24,
            onTap: _toggleMic,
          ),
        ),
        Expanded(
          child: _controlItem(
            icon: camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: 'Kamera',
            color: camOn ? AppColors.blue : Colors.white24,
            onTap: _toggleCamera,
          ),
        ),
        Expanded(
          child: _controlItem(
            icon: subtitlesOn ? Icons.translate_rounded : Icons.translate_outlined,
            label: 'Çeviri',
            color: subtitlesOn ? AppColors.purple : Colors.white24,
            onTap: () async {
              setState(() => subtitlesOn = !subtitlesOn);
              if (subtitlesOn && micOn) {
                await _startSubtitleRecording();
              } else {
                await _stopSubtitleRecording();
              }
            },
          ),
        ),
        Expanded(
          child: _controlItem(
            icon: Icons.sentiment_satisfied_alt_rounded,
            label: 'Avatar',
            color: Colors.white24,
            onTap: () => _sendReaction('🙂'),
          ),
        ),
        Expanded(
          child: _controlItem(
            icon: Icons.call_end_rounded,
            label: 'Kapat',
            color: AppColors.red,
            onTap: _hangUp,
          ),
        ),
      ],
    ),
  );
}


  Widget _controlItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color == Colors.white24 ? Colors.white.withOpacity(0.08) : color,
              shape: BoxShape.circle,
              boxShadow: color == Colors.white24 ? [] : [BoxShadow(color: color.withOpacity(0.22), blurRadius: 18)],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }

  
Widget _chatPanel() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF081120).withOpacity(0.98),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
          child: Row(
            children: [
              const Text('Sohbet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _messages.isEmpty
                ? const Center(child: Text('İlk mesajı sen gönder'))
                : ListView.separated(
                    reverse: true,
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _messages[_messages.length - 1 - index];
                      return Align(
                        alignment: item.isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.isMine ? AppColors.purple : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.text),
                              if (item.translatedText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(item.translatedText, style: const TextStyle(color: Colors.white70)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: _inputDecoration('Mesaj yaz...', suffixIcon: Icons.translate_rounded),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _sendChatMessage,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}


class _TopRoundButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? badgeText;
  final VoidCallback? onTap;

  const _TopRoundButton({
    required this.icon,
    this.label,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: label == null ? 12 : 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: badgeText == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: Colors.white),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(label!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ],
            )
          : Badge(
              label: Text(badgeText!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 21, color: Colors.white),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(label!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: content,
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar();

  @override
  Widget build(BuildContext context) {
    final heights = <double>[8, 12, 18, 28, 18, 34, 24, 16, 36, 20, 12, 26, 16, 10];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: heights
          .map(
            (h) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.7), blurRadius: 10)],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BottomFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _BottomFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(label),
      dropdownColor: AppColors.card,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      selectedItemBuilder: (context) {
        return items
            .map(
              (e) => Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(languageFlag(e), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();
      },
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Text(languageFlag(e), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(e)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  const _AppTextField({
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label, hint: hint),
    );
  }
}

InputDecoration _inputDecoration(String label, {String? hint, IconData? suffixIcon}) {
  return InputDecoration(
    labelText: label.isEmpty ? null : label,
    hintText: hint,
    suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
    filled: true,
    fillColor: Colors.white.withOpacity(0.03),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      borderRadius: BorderRadius.circular(18),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.purple),
      borderRadius: BorderRadius.circular(18),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: gradient.first.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: gradient.last),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class _ChatMessage {

  final String text;
  final String translatedText;
  final bool isMine;

  const _ChatMessage({
    required this.text,
    required this.translatedText,
    required this.isMine,
  });
}
