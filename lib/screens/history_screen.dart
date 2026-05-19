part of '../main.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appRefresh,
      builder: (context, _, _) {
        return FutureBuilder<List<CallHistoryEntry>>(
          future: AppStore.loadHistory(),
          builder: (context, snapshot) {
            final history = snapshot.data ?? const <CallHistoryEntry>[];
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: const Text('Geçmiş'),
              ),
              body: history.isEmpty
                  ? const Center(child: Text('Henüz geçmiş yok'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = history[index];
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.relativeLabel,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${item.sourceLanguage} ↔ ${item.targetLanguage}',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Süre: ${item.durationLabel} • Katılımcı: ${item.memberCount} • Kod: ${item.privateCode}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.purple,
                                    ),
                                  ),
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
