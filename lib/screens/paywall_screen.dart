import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenuecat_service.dart';
import '../services/usage_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  UsageSnapshot? _usage;
  List<Package> _packages = const <Package>[];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usage = await UsageService.snapshot();
    final packages = await RevenueCatService.availablePackages();
    if (!mounted) return;
    setState(() {
      _usage = usage;
      _packages = packages;
      _message = RevenueCatService.lastError;
      _loading = false;
    });
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await RevenueCatService.purchase(package);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = result.message;
    });
    if (result.isPro && mounted) Navigator.pop(context, true);
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await RevenueCatService.restore();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = result.message;
    });
    if (result.isPro && mounted) Navigator.pop(context, true);
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
          const SizedBox(height: 26),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading && _packages.isEmpty)
            _PaywallMessage(
              text:
                  _message ??
                  'Abonelik ürünleri yüklenemedi. RevenueCat API key ve App Store ürünlerini kontrol et.',
            ),
          if (!_loading)
            ..._packages.map(
              (package) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                  onPressed: () => _purchase(package),
                  child: Text(
                    '${package.storeProduct.title} • ${package.storeProduct.priceString}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: _loading ? null : _restore,
            child: const Text('Satın alımı geri yükle'),
          ),
          if (_message != null && _packages.isNotEmpty)
            _PaywallMessage(text: _message!),
        ],
      ),
    );
  }
}

class _PaywallMessage extends StatelessWidget {
  final String text;

  const _PaywallMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
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
