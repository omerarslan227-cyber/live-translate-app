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
      title: 'BridgeCall',
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
        ),
        child: NavigationBar(
          backgroundColor: AppColors.card,
          indicatorColor: Colors.white10,
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Mesajlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history_toggle_off),
              label: 'Geçmiş',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
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
                  colors: [Color(0xFF050816), Color(0xFF071327), Color(0xFF0A1021)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.call_rounded, color: AppColors.purple, size: 30),
                        SizedBox(width: 10),
                        Text(
                          'BridgeCall',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Icon(Icons.settings_outlined, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _StatusStrip(profileName: data.profile.displayName),
                    const SizedBox(height: 14),
                    _LastRoomCard(lastHistory: data.lastHistory),
                    const SizedBox(height: 18),
                    _ActionButton(
                      title: 'Oda Oluştur',
                      subtitle: 'Yeni bir oda oluştur ve davet et',
                      icon: Icons.add,
                      gradient: const [Color(0xFF9D6BFF), Color(0xFF6D48E6)],
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
                      gradient: const [Color(0xFF4F8CFF), Color(0xFF3567FF)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => JoinRoomScreen(profile: data.profile)),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
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
              profileName.isEmpty ? 'BridgeCall’a hoş geldin' : 'Hoş geldin, $profileName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          const Text('🔥 Popüler: Türkçe ↔ Rusça', style: TextStyle(color: Colors.white70)),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Son oda', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 8),
                Text(
                  lastHistory?.roomName ?? 'Henüz oda yok',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  lastHistory == null
                      ? 'İlk konuşmanı başlat'
                      : '${lastHistory!.sourceLanguage} ↔ ${lastHistory!.targetLanguage} • ${lastHistory!.durationLabel}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                'Canlı Çeviri Denemesi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$from   $source', style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 6),
              Text('$to   $target', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
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
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: const [
              Text('Son Konuşmalar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Henüz gerçek konuşma kaydı yok. İlk odayı başlatınca burada görünecek.', style: TextStyle(color: Colors.white70)),
            )
          else
            ...history.take(3).map((entry) => Padding(
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
    return Row(
      children: [
        const CircleAvatar(radius: 24, backgroundColor: Colors.white10, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 3),
              Text('${entry.sourceLanguage} ↔ ${entry.targetLanguage} • ${entry.durationLabel}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(entry.relativeLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.purple),
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
      ],
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
          colors: [Color(0xFF22133E), Color(0xFF271634)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arkadaşını Davet Et', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Davet linkini paylaş, birlikte konuşun!', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Icon(Icons.card_giftcard_rounded, size: 38, color: Color(0xFFFF6B6B)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
                  onPressed: () async {
                    if (lastHistory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Önce bir oda oluştur veya bir odaya katıl.')),
                      );
                      return;
                    }
                    final link = AppStore.inviteLink(lastHistory!.roomName, lastHistory!.privateCode);
                    await Share.share('BridgeCall odama katıl: $link');
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Paylaş'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.purple),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    if (lastHistory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kopyalanacak aktif oda bulunamadı.')),
                      );
                      return;
                    }
                    final link = AppStore.inviteLink(lastHistory!.roomName, lastHistory!.privateCode);
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Davet linki kopyalandı')));
                    }
                  },
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Link Kopyala'),
                ),
              ),
            ],
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

  final List<String> languages = const ['Türkçe', 'Rusça', 'Ukraynaca', 'İngilizce'];

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

  final List<String> languages = const ['Türkçe', 'Rusça', 'Ukraynaca', 'İngilizce'];
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final isTablet = size.width >= 600;
    final horizontal = isWide ? 28.0 : 18.0;
    final previewWidth = isWide ? 180.0 : (isTablet ? 136.0 : 112.0);
    final previewHeight = isWide ? 240.0 : (isTablet ? 190.0 : 160.0);
    final reactionBottom = _showChat ? 340.0 : 214.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _remoteRenderer.srcObject != null
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF111827), Color(0xFF231A34), Color(0xFF0A1020)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.videocam_off_rounded, size: 82, color: Colors.white24),
                          SizedBox(height: 10),
                          Text(
                            'Karşı taraf bekleniyor',
                            style: TextStyle(color: Colors.white60, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.40),
                    Colors.transparent,
                    Colors.black.withOpacity(0.60),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roomName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isWide ? 28 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: AppColors.green, size: 10),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$_callDuration  •  $statusText',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _TopRoundButton(icon: Icons.groups_rounded, label: '$memberCount'),
                      const SizedBox(width: 8),
                      _TopRoundButton(
                        icon: Icons.chat_bubble_outline,
                        badgeText: _messages.isEmpty ? null : '${_messages.length}',
                        onTap: () => setState(() => _showChat = !_showChat),
                      ),
                      const SizedBox(width: 8),
                      _TopRoundButton(
                        icon: Icons.ios_share_rounded,
                        onTap: () async {
                          final link = AppStore.inviteLink(widget.roomName, widget.privateCode);
                          await Share.share('BridgeCall odama katıl: $link');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          width: previewWidth,
                          height: previewHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: cameraStarted
                                      ? RTCVideoView(
                                          _localRenderer,
                                          mirror: true,
                                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                        )
                                      : Container(color: Colors.black38),
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.flip_camera_android, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_reactionEmoji != null)
                          Positioned(
                            right: 18,
                            bottom: reactionBottom,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 250),
                              scale: _reactionEmoji == null ? 0.5 : 1,
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(_reactionEmoji!, style: const TextStyle(fontSize: 44)),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: isWide ? 820 : 560),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(isWide ? 20 : 16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.42),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$sourceLanguageName (Siz)',
                                                style: const TextStyle(color: Colors.white70),
                                              ),
                                            ),
                                            const Icon(Icons.graphic_eq, color: AppColors.purple),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          subtitleText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: isWide ? 22 : 19,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$targetLanguageName (Çeviri)',
                                                style: const TextStyle(color: Colors.white70),
                                              ),
                                            ),
                                            const Icon(Icons.graphic_eq, color: AppColors.purple),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          translatedText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: isWide ? 22 : 19,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const _WaveBar(),
                                  const SizedBox(height: 8),
                                  Text(
                                    isRecording ? 'Sen konuşuyorsun...' : statusText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Color(0xFFD7C8FF)),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                                    ),
                                    child: Text(
                                      'Oda kodu: ${widget.privateCode}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: isWide ? 18 : 10,
                                    runSpacing: 12,
                                    children: [
                                      _controlItem(
                                        icon: micOn ? Icons.mic : Icons.mic_off,
                                        label: 'Mikrofon',
                                        color: micOn ? AppColors.green : Colors.white24,
                                        onTap: _toggleMic,
                                      ),
                                      _controlItem(
                                        icon: camOn ? Icons.videocam : Icons.videocam_off,
                                        label: 'Kamera',
                                        color: camOn ? AppColors.blue : Colors.white24,
                                        onTap: _toggleCamera,
                                      ),
                                      _controlItem(
                                        icon: subtitlesOn ? Icons.translate : Icons.translate_outlined,
                                        label: 'Çeviri',
                                        color: subtitlesOn ? AppColors.purple : Colors.white24,
                                        onTap: () async {
                                          setState(() => subtitlesOn = !subtitlesOn);
                                          if (subtitlesOn) {
                                            await _startSubtitleRecording();
                                          } else {
                                            await _stopSubtitleRecording();
                                          }
                                        },
                                      ),
                                      _controlItem(
                                        icon: Icons.auto_awesome_rounded,
                                        label: 'Avatar',
                                        color: Colors.white24,
                                        onTap: () => setState(() => _showChat = !_showChat),
                                      ),
                                      _controlItem(
                                        icon: Icons.call_end,
                                        label: 'Kapat',
                                        color: AppColors.red,
                                        onTap: _hangUp,
                                      ),
                                    ],
                                  ),
                                  if (_showChat) ...[
                                    const SizedBox(height: 16),
                                    _chatPanel(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: _showChat ? 304 : 180,
                          child: Column(
                            children: [
                              for (final emoji in ['👍', '😍', '😂', '😮', '👏'])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    onTap: () => _sendReaction(emoji),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _controlItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.25), blurRadius: 20),
                ],
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _chatPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Sohbet', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showChat = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 118,
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
                          constraints: const BoxConstraints(maxWidth: 250),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: _inputDecoration('Mesaj yaz...', suffixIcon: Icons.translate),
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
                  child: const Icon(Icons.send_rounded),
                ),
              ),
            ],
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
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: badgeText == null
          ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon), if (label != null) ...[const SizedBox(width: 8), Text(label!)]])
          : Badge(
              label: Text(badgeText!),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon), if (label != null) ...[const SizedBox(width: 8), Text(label!)]]),
            ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: child);
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar();

  @override
  Widget build(BuildContext context) {
    final List<double> heights = [
      10.0,
      16.0,
      26.0,
      40.0,
      24.0,
      50.0,
      28.0,
      16.0,
      44.0,
      30.0,
      14.0,
      36.0,
      18.0,
      12.0,
    ];
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
                boxShadow: const [BoxShadow(color: AppColors.purple, blurRadius: 10)],
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      decoration: _inputDecoration(label),
      dropdownColor: AppColors.card,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
      borderSide: const BorderSide(color: AppColors.border),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: gradient.first.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: gradient.last),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 16)),
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
        color: AppColors.card.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 8)),
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
