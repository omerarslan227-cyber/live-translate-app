part of '../main.dart';

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
      builder: (context, _, _) {
        return FutureBuilder<_HomeData>(
          future: _loadHomeData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _HomeData();
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF050816),
                    Color(0xFF071327),
                    Color(0xFF0A1021),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.call_rounded,
                          color: AppColors.purple,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'BridgeCall',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ses Tanılama',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VoiceDiagnosticsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.monitor_heart_outlined,
                            color: Colors.white70,
                          ),
                        ),
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
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateRoomScreen(profile: data.profile),
                          ),
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
                          MaterialPageRoute(
                            builder: (_) =>
                                JoinRoomScreen(profile: data.profile),
                          ),
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.circle, color: AppColors.green, size: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              profileName.isEmpty
                  ? 'BridgeCall\'a hoş geldin'
                  : 'Hoş geldin, $profileName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Text(
            '🔥 Popüler: Türkçe ↔ Rusça',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70),
          ),
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
    return GlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Son oda', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 8),
              Text(
                lastHistory?.roomName ?? 'Hen?z oda yok',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lastHistory == null
                    ? '?lk konu?man? ba?lat'
                    : '${lastHistory!.sourceLanguage} ? ${lastHistory!.targetLanguage} ? ${lastHistory!.durationLabel}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          );
          final button = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
            child: Text(
              lastHistory == null ? 'Haz?r De?il' : 'Tekrar Ba?lan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 14), button],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                'Canlı Çeviri Denemesi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                ),
              ),
              Spacer(),
              Text('● Canlı', style: TextStyle(color: AppColors.green)),
            ],
          ),
          SizedBox(height: 14),
          _DemoLine(
            from: 'EN',
            to: 'TR',
            source: 'Hello, how are you?',
            target: 'Merhaba, nasılsın?',
          ),
          SizedBox(height: 12),
          _DemoLine(
            from: 'EN',
            to: 'TR',
            source: 'Where are you from?',
            target: 'Nerelisin?',
          ),
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
              Text(
                '$to   $target',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: const [
              Text(
                'Son Konuşmalar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Henüz gerçek konuşma kaydı yok. İlk odayı başlatınca burada görünecek.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ...history
                .take(3)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ConversationTile(entry: entry),
                  ),
                ),
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
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.roomName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${entry.sourceLanguage} ↔ ${entry.targetLanguage} • ${entry.durationLabel}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.relativeLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.purple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                    Text(
                      'Arkadaşını Davet Et',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Davet linkini paylaş, birlikte konuşun!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.card_giftcard_rounded,
                size: 38,
                color: Color(0xFFFF6B6B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                  ),
                  onPressed: () async {
                    if (lastHistory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Önce bir oda oluştur veya bir odaya katıl.',
                          ),
                        ),
                      );
                      return;
                    }
                    final link = AppStore.inviteLink(
                      lastHistory!.roomName,
                      lastHistory!.privateCode,
                    );
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
                        const SnackBar(
                          content: Text('Kopyalanacak aktif oda bulunamadı.'),
                        ),
                      );
                      return;
                    }
                    final link = AppStore.inviteLink(
                      lastHistory!.roomName,
                      lastHistory!.privateCode,
                    );
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Davet linki kopyalandı'),
                        ),
                      );
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
      builder: (context, _, _) {
        return FutureBuilder<List<StoredMessage>>(
          future: AppStore.loadMessages(),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? const <StoredMessage>[];
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: const Text('Mesajlar'),
              ),
              body: messages.isEmpty
                  ? const Center(child: Text('Henüz kayıtlı mesaj yok'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = messages[index];
                        return GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.roomName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.isMine ? 'Ben' : 'Karşı',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(item.text),
                              if (item.translatedText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.translatedText,
                                  style: const TextStyle(color: Colors.white70),
                                ),
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
