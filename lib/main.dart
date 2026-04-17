import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String baseWsUrl =
    'wss://live-translate-backed-production.up.railway.app';

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
              icon: Badge(label: Text('3'), child: Icon(Icons.chat_bubble_outline)),
              selectedIcon: Badge(label: Text('3'), child: Icon(Icons.chat_bubble)),
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
                Icon(Icons.translate_rounded, color: AppColors.purple, size: 30),
                SizedBox(width: 10),
                Text(
                  'Live Translate',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Icon(Icons.settings_outlined, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 18),
            const _StatusStrip(),
            const SizedBox(height: 14),
            const _LastRoomCard(),
            const SizedBox(height: 18),
            _ActionButton(
              title: 'Oda Oluştur',
              subtitle: 'Yeni bir oda oluştur ve davet et',
              icon: Icons.add,
              gradient: const [Color(0xFF9D6BFF), Color(0xFF6D48E6)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
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
                  MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            const _DemoCard(),
            const SizedBox(height: 16),
            const _RecentConversationsCard(),
            const SizedBox(height: 16),
            const _InviteCard(),
          ],
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: const [
          Icon(Icons.circle, color: AppColors.green, size: 12),
          SizedBox(width: 8),
          Text('38 kişi aktif', style: TextStyle(fontWeight: FontWeight.w600)),
          Spacer(),
          Text('🔥 Popüler: Türkçe ↔ Rusça', style: TextStyle(color: Colors.white70)),
          SizedBox(width: 6),
          Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}

class _LastRoomCard extends StatelessWidget {
  const _LastRoomCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Son oda', style: TextStyle(color: Colors.white60)),
                SizedBox(height: 8),
                Text('oda1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('• 2 kişi • 00:12:36', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JoinRoomScreen(
                    initialRoomName: 'oda1',
                    initialCode: '123456',
                  ),
                ),
              );
            },
            child: const Text('Tekrar Bağlan'),
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
        children: [
          Row(
            children: const [
              Text(
                'Canlı Çeviri Denemesi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple),
              ),
              Spacer(),
              Text('● Canlı', style: TextStyle(color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 14),
          const _DemoLine(from: 'EN', to: 'TR', source: 'Hello, how are you?', target: 'Merhaba, nasılsın?'),
          const SizedBox(height: 12),
          const _DemoLine(from: 'EN', to: 'TR', source: 'Where are you from?', target: 'Nerelisin?'),
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
  const _RecentConversationsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: const [
              Text('Son Konuşmalar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Spacer(),
              Text('Tümünü Gör', style: TextStyle(color: AppColors.purple)),
            ],
          ),
          const SizedBox(height: 14),
          const _ConversationTile(
            name: 'Ahmet',
            subtitle: 'Türkçe ↔ Rusça',
            trailing: 'Bugün 14:30',
          ),
          const SizedBox(height: 12),
          const _ConversationTile(
            name: 'Rusça Pratik',
            subtitle: '2 kişi • 00:18:22',
            trailing: 'Dün 20:15',
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String trailing;

  const _ConversationTile({
    required this.name,
    required this.subtitle,
    required this.trailing,
  });

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
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(trailing, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.purple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {},
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard();

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
      child: Row(
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
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePlaceholderScreen(
      title: 'Mesajlar',
      subtitle: 'Sohbet geçmişi ve otomatik çevrilen mesajlar burada listelenir.',
      icon: Icons.chat_bubble_rounded,
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePlaceholderScreen(
      title: 'Geçmiş',
      subtitle: 'Eski odalar, bağlantı süresi ve son konuşmalar bu alanda görünür.',
      icon: Icons.history_rounded,
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePlaceholderScreen(
      title: 'Profil',
      subtitle: 'Avatar modu, premium, tercih edilen dil ve hesap ayarları burada yönetilir.',
      icon: Icons.person,
    );
  }
}

class _SimplePlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SimplePlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72, color: AppColors.purple),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

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
  }

  String _generateRoomCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return now.substring(now.length - 6);
  }

  void _openCall({bool quick = false}) {
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
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Oda Oluştur')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          _GlassCard(
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.purple, size: 34),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hızlı Başlat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('En popüler ayarlarla hemen odayı oluştur', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
                  onPressed: () => _openCall(quick: true),
                  child: const Text('Hızlı Başlat'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ayarlar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _AppTextField(controller: roomController, label: 'Oda adı'),
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
                    const SizedBox(width: 14),
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white54),
                    const SizedBox(width: 14),
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
                    DropdownMenuItem(value: 'Özel oda (kod ile giriş)', child: Text('Özel oda (kod ile giriş)')),
                    DropdownMenuItem(value: 'Herkese açık oda', child: Text('Herkese açık oda')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => setState(() => showAdvanced = !showAdvanced),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Gelişmiş Ayarlar')),
                        Icon(showAdvanced ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                if (showAdvanced) ...[
                  const SizedBox(height: 14),
                  _AppTextField(controller: codeController, label: 'Özel oda kodu'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => codeController.text = _generateRoomCode()),
                      icon: const Icon(Icons.refresh),
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
            label: const Text('Odayı Başlat', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              final roomLink = 'livetranslate://join?room=${roomController.text.trim()}&code=${codeController.text.trim()}';
              await Clipboard.setData(ClipboardData(text: roomLink));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link kopyalandı')));
              }
            },
            icon: const Icon(Icons.link_rounded),
            label: const Text('Link paylaş'),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _BottomFeature(icon: Icons.schedule, title: 'Günlük Hak', subtitle: '10 dk / 10 dk', color: AppColors.yellow)),
              SizedBox(width: 12),
              Expanded(child: _BottomFeature(icon: Icons.lock, title: 'Güvenli', subtitle: 'Uçtan uca şifreleme', color: AppColors.green)),
              SizedBox(width: 12),
              Expanded(child: _BottomFeature(icon: Icons.hd, title: 'Yüksek Kalite', subtitle: 'HD ses & video', color: AppColors.purple)),
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

  const JoinRoomScreen({super.key, this.initialRoomName, this.initialCode});

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
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Odaya Katıl')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppTextField(controller: roomController, label: 'Oda adı'),
                const SizedBox(height: 14),
                _AppTextField(controller: codeController, label: 'Oda kodu', hint: '6 haneli oda kodunu gir'),
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
                  label: const Text('Odaya Katıl', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Kod nasıl alınır?'),
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
  bool _showChat = true;
  bool _isConnecting = false;

  String subtitleText = 'Canlı altyazı burada görünecek';
  String translatedText = 'Çeviri burada görünecek';
  String statusText = 'Hazırlanıyor...';
  String? myClientId;
  int memberCount = 1;

  late String sourceLanguageName;
  late String targetLanguageName;
  DateTime _callStart = DateTime.now();

  final List<_ChatMessage> _messages = [
    _ChatMessage(text: 'Привет! Как дела?', translatedText: 'Merhaba! Nasılsın?', isMine: false),
    _ChatMessage(text: 'Merhaba 👋', translatedText: '', isMine: true),
  ];

  String? _reactionEmoji;
  Timer? _reactionTimer;

  final Map<String, String> sourceLanguages = const {
    'Türkçe': 'TR',
    'Rusça': 'RU',
    'Ukraynaca': 'UK',
    'İngilizce': 'EN',
  };

  final Map<String, String> targetLanguages = const {
    'Türkçe': 'TR',
    'Rusça': 'RU',
    'Ukraynaca': 'UK',
    'İngilizce': 'EN-US',
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
    _initAll();
  }

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _recorder.openRecorder();
    await _openCamera();
    await _joinRoom();
    setState(() {
      statusText = widget.isOwner ? 'Oda hazır, katılımcı bekleniyor' : 'Bağlantı kuruluyor';
    });
  }

  Future<void> _openCamera() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
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
          statusText = 'Kamera açıldı';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusText = 'Kamera hatası: $e';
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
          statusText = 'Bağlantı: $state';
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
              subtitleText = data['original'] ?? subtitleText;
              translatedText = data['translated'];
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
    if (isRecording) return;
    _connectTranslateSocket();
    isRecording = true;

    while (isRecording) {
      try {
        final path = await _tempWavPath();
        await _recorder.startRecorder(
          toFile: path,
          codec: Codec.pcm16WAV,
          numChannels: 1,
          sampleRate: 16000,
        );
        await Future.delayed(const Duration(seconds: 2));
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
        if (mounted) setState(() => statusText = 'Kayıt hatası: $e');
        isRecording = false;
      }
    }
  }

  Future<void> _stopSubtitleRecording() async {
    isRecording = false;
    try {
      await _recorder.stopRecorder();
    } catch (_) {}
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
      if (mounted) setState(() => myClientId = data['clientId']);
      return;
    }

    if (data['room'] != null && data['room'] != widget.roomName) return;

    switch (type) {
      case 'error':
        if (mounted) setState(() => statusText = data['message'] ?? 'Bilinmeyen hata');
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
        if (mounted) setState(() {
          memberCount = data['memberCount'] ?? 2;
          statusText = 'Odaya giriş onaylandı';
        });
        return;
      case 'join_rejected':
        if (mounted) setState(() => statusText = 'Odaya giriş reddedildi');
        return;
      case 'member_joined':
        if (mounted) setState(() {
          memberCount += 1;
          statusText = 'Yeni bir kullanıcı katıldı';
        });
        if (widget.isOwner) {
          await _startCall();
        }
        return;
      case 'member_left':
        if (mounted) setState(() {
          memberCount = memberCount > 1 ? memberCount - 1 : 1;
          statusText = 'Bir kullanıcı odadan çıktı';
        });
        return;
      case 'room_closed':
        if (mounted) {
          setState(() => statusText = 'Oda sahibi çağrıyı kapattı');
          Navigator.pop(context);
        }
        return;
      case 'left_room':
        if (mounted) setState(() => statusText = 'Odadan çıkıldı');
        return;
      case 'chat_message':
        final incoming = data['text']?.toString() ?? '';
        final translated = data['translatedText']?.toString() ?? '';
        if (incoming.isNotEmpty && mounted) {
          setState(() {
            _messages.add(_ChatMessage(text: incoming, translatedText: translated, isMine: false));
          });
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
      final desc = RTCSessionDescription(data['sdp'], data['sdpType']);
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
      final desc = RTCSessionDescription(data['sdp'], data['sdpType']);
      await _peerConnection!.setRemoteDescription(desc);
      if (mounted) setState(() => statusText = 'Bağlantı tamamlandı');
    } else if (type == 'candidate') {
      final c = data['candidate'];
      if (c != null) {
        await _peerConnection!.addCandidate(
          RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
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
    setState(() {
      _messages.add(_ChatMessage(text: text, translatedText: '', isMine: true));
      _chatController.clear();
    });
    _sendSignal({'type': 'chat_message', 'room': widget.roomName, 'text': text, 'translatedText': ''});
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

  Future<void> _hangUp() async {
    try {
      _sendSignal({'type': 'leave_room'});
    } catch (_) {}

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

  @override
  void dispose() {
    _reactionTimer?.cancel();
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
                        colors: [Color(0xFF131827), Color(0xFF3D2A1E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.videocam_rounded, size: 80, color: Colors.white24),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.25), Colors.transparent, Colors.black.withOpacity(0.45)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: 52,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.roomName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.circle, color: AppColors.green, size: 10),
                          const SizedBox(width: 8),
                          Text(_callDuration, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                _TopRoundButton(icon: Icons.groups_rounded, label: '$memberCount'),
                const SizedBox(width: 10),
                _TopRoundButton(
                  icon: Icons.chat_bubble_outline,
                  badgeText: '3',
                  onTap: () => setState(() => _showChat = !_showChat),
                ),
                const SizedBox(width: 10),
                const _TopRoundButton(icon: Icons.more_horiz_rounded),
              ],
            ),
          ),
          Positioned(
            top: 110,
            right: 18,
            width: 112,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
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
              right: 28,
              top: 300,
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
            left: 18,
            right: 18,
            bottom: _showChat ? 240 : 124,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                      const Expanded(child: Text('Türkçe (Siz)', style: TextStyle(color: Colors.white70))),
                      const Icon(Icons.graphic_eq, color: AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitleText, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Text('Rusça (Karşı taraf)', style: TextStyle(color: Colors.white70))),
                      const Icon(Icons.graphic_eq, color: AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(translatedText, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: _showChat ? 178 : 88,
            child: const _WaveBar(),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: _showChat ? 156 : 66,
            child: Center(
              child: Text(
                isRecording ? 'Sen konuşuyorsun...' : statusText,
                style: const TextStyle(color: Color(0xFFD7C8FF)),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: _showChat ? 0 : 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlItem(icon: micOn ? Icons.mic : Icons.mic_off, label: 'Mikrofon', color: micOn ? AppColors.green : Colors.white24, onTap: _toggleMic),
                    _controlItem(icon: camOn ? Icons.videocam : Icons.videocam_off, label: 'Kamera', color: Colors.white24, onTap: _toggleCamera),
                    _controlItem(icon: subtitlesOn ? Icons.translate : Icons.translate_outlined, label: 'Çeviri', color: AppColors.purple, onTap: () async {
                      setState(() => subtitlesOn = !subtitlesOn);
                      if (subtitlesOn) {
                        await _startSubtitleRecording();
                      } else {
                        await _stopSubtitleRecording();
                      }
                    }),
                    _controlItem(icon: Icons.emoji_emotions_outlined, label: 'Avatar', color: Colors.white24, onTap: () => setState(() => _showChat = !_showChat)),
                    _controlItem(icon: Icons.call_end, label: 'Kapat', color: AppColors.red, onTap: _hangUp),
                  ],
                ),
                if (_showChat) ...[
                  const SizedBox(height: 16),
                  _chatPanel(),
                ],
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: _showChat ? 302 : 190,
            child: Column(
              children: [
                for (final emoji in ['👍', '😍', '😂', '😮', '👏'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _sendReaction(emoji),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                      ),
                    ),
                  ),
              ],
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
            child: ListView.separated(
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
      10.0, 16.0, 26.0, 40.0, 24.0, 50.0, 28.0,
      16.0, 44.0, 30.0, 14.0, 36.0, 18.0, 12.0,
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
