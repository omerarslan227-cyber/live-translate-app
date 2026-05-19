import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../services/paywall_social_proof_service.dart';
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
  PaywallSocialProofSnapshot? _socialProof;
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
    final socialProof = await PaywallSocialProofService.load();
    if (!mounted) return;
    setState(() {
      _usage = usage;
      _packages = packages;
      _socialProof = socialProof;
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
            _SocialProofStrip(snapshot: _socialProof),
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

class _SocialProofStrip extends StatefulWidget {
  final PaywallSocialProofSnapshot? snapshot;

  const _SocialProofStrip({required this.snapshot});

  @override
  State<_SocialProofStrip> createState() => _SocialProofStripState();
}

class _SocialProofStripState extends State<_SocialProofStrip> {
  int _testimonialIndex = 0;

  @override
  void didUpdateWidget(covariant _SocialProofStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_testimonialIndex >= (widget.snapshot?.testimonials.length ?? 0)) {
      _testimonialIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    if (snapshot == null) return const _SocialProofSkeleton();

    final metrics = snapshot.metrics;
    final testimonials = snapshot.testimonials;
    if (!snapshot.hasPublicProof) {
      return const _SocialProofSkeleton(
        caption:
            'Verified metrics will appear after production data is configured.',
      );
    }

    final testimonial = testimonials.isEmpty
        ? null
        : testimonials[_testimonialIndex % testimonials.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _PremiumTrustBadge(),
              const Spacer(),
              if (testimonials.length > 1)
                IconButton(
                  tooltip: 'Next testimonial',
                  onPressed: () => setState(() {
                    _testimonialIndex =
                        (_testimonialIndex + 1) % testimonials.length;
                  }),
                  icon: const Icon(Icons.auto_awesome_rounded),
                ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final metric in metrics.take(2))
                  Expanded(child: _MetricTile(metric: metric)),
              ],
            ),
          ],
          if (testimonial != null) ...[
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Align(
                key: ValueKey(testimonial.quote),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${testimonial.quote}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.32,
                      ),
                    ),
                    if (testimonial.attribution.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        testimonial.attribution,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumTrustBadge extends StatelessWidget {
  const _PremiumTrustBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 17),
          SizedBox(width: 7),
          Text(
            'Verified social proof',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final PaywallMetric metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              metric.label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialProofSkeleton extends StatelessWidget {
  final String caption;

  const _SocialProofSkeleton({
    this.caption =
        'Production social proof will appear after verified metrics are configured.',
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 18, color: Colors.white),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Container(height: 52, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 52, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            Text(caption, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
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
