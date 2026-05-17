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
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF15103A), Color(0xFF071327)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 92, 22, 24),
          children: [
            const _PaywallHero(),
            const SizedBox(height: 18),
            Text(
              usage?.isPro == true
                  ? 'Pro aktif. Sinirsiz canli ceviri kullanabilirsin.'
                  : 'Ucretsiz gunluk 3 dakika doldugunda Pro ile sinirsiz devam et.',
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 18),
            const _SocialProofStrip(),
            const SizedBox(height: 18),
            const _PremiumBenefitGrid(),
            const SizedBox(height: 22),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _packages.isEmpty)
              _PaywallMessage(
                text:
                    _message ??
                    'Abonelik urunleri yuklenemedi. RevenueCat API key ve App Store urunlerini kontrol et.',
              ),
            if (!_loading)
              ..._sortedPackages.map(
                (package) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanButton(
                    package: package,
                    highlighted: _isYearly(package),
                    onPressed: () => _purchase(package),
                  ),
                ),
              ),
            TextButton(
              onPressed: _loading ? null : _restore,
              child: const Text('Satin alimi geri yukle'),
            ),
            if (_message != null && _packages.isNotEmpty)
              _PaywallMessage(text: _message!),
          ],
        ),
      ),
    );
  }

  List<Package> get _sortedPackages {
    final packages = [..._packages];
    packages.sort((a, b) {
      if (_isYearly(a) == _isYearly(b)) return 0;
      return _isYearly(a) ? -1 : 1;
    });
    return packages;
  }

  bool _isYearly(Package package) {
    final id = package.identifier.toLowerCase();
    final title = package.storeProduct.title.toLowerCase();
    return id.contains('annual') ||
        id.contains('year') ||
        title.contains('year') ||
        title.contains('yil');
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF4F8CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 44),
          SizedBox(height: 16),
          Text(
            'BridgeCall Pro',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'AI sesli ceviri, canli altyazi ve global gorusmeler icin limitsiz deneyim.',
            style: TextStyle(color: Colors.white, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SocialProofStrip extends StatelessWidget {
  const _SocialProofStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.verified_rounded, color: Color(0xFF22C55E)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Beta kullanicilari icin hizli, stabil ve reklamsiz canli ceviri.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PremiumBenefitGrid extends StatelessWidget {
  const _PremiumBenefitGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FeatureRow(
          icon: Icons.all_inclusive_rounded,
          text: 'Sinirsiz canli ceviri gorusmesi',
        ),
        _FeatureRow(
          icon: Icons.speed_rounded,
          text: 'Dusuk gecikmeli altyazi ve konusma cevirisi',
        ),
        _FeatureRow(
          icon: Icons.language_rounded,
          text: 'Buyuk pazar dilleri ve hizli dil degistirme',
        ),
        _FeatureRow(
          icon: Icons.security_rounded,
          text: 'TURN destekli daha stabil gorusme altyapisi',
        ),
      ],
    );
  }
}

class _PlanButton extends StatelessWidget {
  final Package package;
  final bool highlighted;
  final VoidCallback onPressed;

  const _PlanButton({
    required this.package,
    required this.highlighted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? const Color(0xFFFBBF24) : Colors.white24,
          width: highlighted ? 1.4 : 1,
        ),
        color: Colors.white.withValues(alpha: highlighted ? 0.10 : 0.06),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlighted)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _PopularBadge(),
                      ),
                    Text(
                      package.storeProduct.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Free trial varsa App Store otomatik gosterir.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                package.storeProduct.priceString,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Most Popular',
        style: TextStyle(
          color: Color(0xFF16120A),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
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
