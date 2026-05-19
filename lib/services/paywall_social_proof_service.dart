import 'dart:convert';

class PaywallMetric {
  final String label;
  final String value;

  const PaywallMetric({required this.label, required this.value});
}

class PaywallTestimonial {
  final String quote;
  final String attribution;

  const PaywallTestimonial({required this.quote, required this.attribution});
}

class PaywallSocialProofSnapshot {
  final List<PaywallMetric> metrics;
  final List<PaywallTestimonial> testimonials;

  const PaywallSocialProofSnapshot({
    required this.metrics,
    required this.testimonials,
  });

  bool get hasPublicProof => metrics.isNotEmpty || testimonials.isNotEmpty;
}

class PaywallSocialProofService {
  const PaywallSocialProofService._();

  static const _activeUsers = String.fromEnvironment('PAYWALL_ACTIVE_USERS');
  static const _appStoreRating = String.fromEnvironment(
    'PAYWALL_APP_STORE_RATING',
  );
  static const _testimonialsJson = String.fromEnvironment(
    'PAYWALL_TESTIMONIALS_JSON',
  );

  static Future<PaywallSocialProofSnapshot> load() async {
    return PaywallSocialProofSnapshot(
      metrics: _metrics(),
      testimonials: _testimonials(),
    );
  }

  static List<PaywallMetric> _metrics() {
    final metrics = <PaywallMetric>[];
    final users = _activeUsers.trim();
    final rating = _appStoreRating.trim();
    if (users.isNotEmpty) {
      metrics.add(PaywallMetric(label: 'Active users', value: users));
    }
    if (rating.isNotEmpty) {
      metrics.add(PaywallMetric(label: 'App Store rating', value: rating));
    }
    return metrics;
  }

  static List<PaywallTestimonial> _testimonials() {
    if (_testimonialsJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(_testimonialsJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => PaywallTestimonial(
              quote: item['quote']?.toString().trim() ?? '',
              attribution: item['attribution']?.toString().trim() ?? '',
            ),
          )
          .where((item) => item.quote.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
