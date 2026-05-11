import 'package:flutter/material.dart';

import '../services/usage_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  UsageSnapshot? _usage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usage = await UsageService.snapshot();
    if (mounted) setState(() => _usage = usage);
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 18),
          const Icon(Icons.workspace_premium_rounded, size: 56),
          const SizedBox(height: 18),
          const Text(
            'BridgeCall Pro',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            usage?.isPro == true
                ? 'Pro aktif. Sınırsız canlı çeviri kullanabilirsin.'
                : 'Ücretsiz günlük 3 dakika dolduğunda Pro ile sınırsız devam et.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 24),
          _FeatureRow(
            icon: Icons.all_inclusive_rounded,
            text: 'Sınırsız canlı çeviri görüşmesi',
          ),
          _FeatureRow(
            icon: Icons.speed_rounded,
            text: 'Düşük gecikmeli altyazı ve konuşma çevirisi',
          ),
          _FeatureRow(
            icon: Icons.language_rounded,
            text: 'Büyük pazar dilleri ve hızlı dil değiştirme',
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            onPressed: () async {
              await UsageService.setDebugPro(true);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Pro Altyapısını Aktifleştir'),
          ),
          const SizedBox(height: 10),
          const Text(
            'RevenueCat ürünleri App Store Connect tarafında bağlanınca bu buton gerçek abonelik akışına çevrilecek.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22C55E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
