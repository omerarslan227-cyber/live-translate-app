import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/language_option.dart';
import '../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget next;

  const OnboardingScreen({super.key, required this.next});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _ambientController;
  int _page = 0;
  String _source = bridgeCallLanguageNames.first;
  String _target = bridgeCallLanguageNames.length > 1
      ? bridgeCallLanguageNames[1]
      : bridgeCallLanguageNames.first;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  Future<void> _finish() async {
    await OnboardingService.markComplete(
      sourceLanguage: _source,
      targetLanguage: _target,
    );
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => widget.next));
  }

  Future<void> _next() async {
    if (_page < 2) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  Future<void> _requestMic() async {
    await Permission.microphone.request();
    await _finish();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_ambientController, _controller]),
        builder: (context, _) {
          final pageValue = _controller.hasClients
              ? (_controller.page ?? _page.toDouble())
              : _page.toDouble();
          return Stack(
            children: [
              _FloatingGradientBackground(
                animation: _ambientController,
                pageValue: pageValue,
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (value) => setState(() => _page = value),
                        children: [
                          _OnboardingPage(
                            pageIndex: 0,
                            currentPage: pageValue,
                            title: 'Canli ceviri gorusmesi',
                            body:
                                'BridgeCall konusmayi algilar, cevirir ve karsi tarafa altyazi veya ses olarak ulastirir.',
                            bullets: const [
                              'AI voice translation',
                              'Gercek zamanli altyazi',
                              'Global communication',
                            ],
                          ),
                          _LanguageStep(
                            currentPage: pageValue,
                            source: _source,
                            target: _target,
                            onSourceChanged: (value) =>
                                setState(() => _source = value),
                            onTargetChanged: (value) =>
                                setState(() => _target = value),
                          ),
                          _OnboardingPage(
                            pageIndex: 2,
                            currentPage: pageValue,
                            title: 'Mikrofon hazirligi',
                            body:
                                'Sesli ceviri icin mikrofon izni gerekir. Izin yoksa BridgeCall net uyari verir.',
                            bullets: const [
                              'Noise suppression',
                              'Echo cancellation',
                              'Canli altyazi pipeline',
                            ],
                            actionLabel: 'Mikrofonu Ac',
                            onAction: _requestMic,
                          ),
                        ],
                      ),
                    ),
                    _OnboardingControls(
                      page: _page,
                      onSkip: _finish,
                      onNext: _next,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingGradientBackground extends StatelessWidget {
  final Animation<double> animation;
  final double pageValue;

  const _FloatingGradientBackground({
    required this.animation,
    required this.pageValue,
  });

  @override
  Widget build(BuildContext context) {
    final motion = animation.value;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050816), Color(0xFF111B34), Color(0xFF15103A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          _FloatingOrb(
            size: 260,
            color: const Color(0xFF8B5CF6),
            left: -70 + (motion * 28) - (pageValue * 14),
            top: 80 + (motion * 24),
          ),
          _FloatingOrb(
            size: 220,
            color: const Color(0xFF4F8CFF),
            right: -60 + (motion * 18),
            bottom: 130 - (motion * 34) + (pageValue * 12),
          ),
          _FloatingOrb(
            size: 140,
            color: const Color(0xFF22C55E),
            right: 44 + (motion * 18),
            top: 78 + (pageValue * 20),
            opacity: 0.20,
          ),
        ],
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double opacity;

  const _FloatingOrb({
    required this.size,
    required this.color,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.opacity = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final int pageIndex;
  final double currentPage;
  final String title;
  final String body;
  final List<String> bullets;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _OnboardingPage({
    required this.pageIndex,
    required this.currentPage,
    required this.title,
    required this.body,
    this.bullets = const [],
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final delta = currentPage - pageIndex;
    final parallax = delta.clamp(-1.0, 1.0) * -34;
    final opacity = (1 - delta.abs()).clamp(0.35, 1.0).toDouble();
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(parallax, 0),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _PremiumMotionCard(),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 22),
              for (final item in bullets) _Bullet(text: item),
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumMotionCard extends StatelessWidget {
  const _PremiumMotionCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/bridgecall_voice.json',
                fit: BoxFit.contain,
                repeat: true,
                frameRate: FrameRate.max,
                filterQuality: FilterQuality.medium,
              ),
              Positioned(
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Text(
                    'Realtime AI translation',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  final double currentPage;
  final String source;
  final String target;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;

  const _LanguageStep({
    required this.currentPage,
    required this.source,
    required this.target,
    required this.onSourceChanged,
    required this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final delta = currentPage - 1;
    return Transform.translate(
      offset: Offset(delta.clamp(-1.0, 1.0) * -24, 0),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _PremiumMotionCard(),
            const SizedBox(height: 24),
            const Text(
              'Dil akisini sec',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ilk aramayi hizli baslat. Gorusme icinde dilleri yine degistirebilirsin.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 24),
            _LanguagePicker(
              label: 'Senin dilin',
              value: source,
              onChanged: onSourceChanged,
            ),
            const SizedBox(height: 12),
            _LanguagePicker(
              label: 'Hedef dil',
              value: target,
              onChanged: onTargetChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  final int page;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _OnboardingControls({
    required this.page,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          ...List.generate(
            3,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: page == index ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: page == index ? const Color(0xFF8B5CF6) : Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onSkip, child: const Text('Atla')),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: onNext,
            child: Text(page == 2 ? 'Basla' : 'Devam'),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguagePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: bridgeCallLanguageNames.contains(value)
          ? value
          : bridgeCallLanguageNames.first,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownColor: const Color(0xFF0B1224),
      items: bridgeCallLanguageNames
          .map(
            (language) =>
                DropdownMenuItem(value: language, child: Text(language)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
