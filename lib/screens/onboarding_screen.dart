import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/language_option.dart';
import '../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget next;

  const OnboardingScreen({super.key, required this.next});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  String _source = bridgeCallLanguageNames.first;
  String _target = bridgeCallLanguageNames.length > 1
      ? bridgeCallLanguageNames[1]
      : bridgeCallLanguageNames.first;

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
        duration: const Duration(milliseconds: 320),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF111B34), Color(0xFF15103A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    const _OnboardingPage(
                      icon: Icons.translate_rounded,
                      title: 'Canli ceviri gorusmesi',
                      body:
                          'BridgeCall konusmayi algilar, cevirir ve karsi tarafa altyazi veya ses olarak ulastirir.',
                      bullets: [
                        'AI voice translation',
                        'Gercek zamanli altyazi',
                        'Global communication',
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _HeroOrb(icon: Icons.language_rounded),
                          const SizedBox(height: 24),
                          const Text(
                            'Dil akisini sec',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ilk aramayi hizli baslat. Gorusme icinde dilleri yine degistirebilirsin.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _LanguagePicker(
                            label: 'Senin dilin',
                            value: _source,
                            onChanged: (value) =>
                                setState(() => _source = value),
                          ),
                          const SizedBox(height: 12),
                          _LanguagePicker(
                            label: 'Hedef dil',
                            value: _target,
                            onChanged: (value) =>
                                setState(() => _target = value),
                          ),
                        ],
                      ),
                    ),
                    _OnboardingPage(
                      icon: Icons.mic_rounded,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    ...List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: _page == index ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 7),
                        decoration: BoxDecoration(
                          color: _page == index
                              ? const Color(0xFF8B5CF6)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: _finish, child: const Text('Atla')),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _next,
                      child: Text(_page == 2 ? 'Basla' : 'Devam'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<String> bullets;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    this.bullets = const [],
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HeroOrb(icon: icon),
          const SizedBox(height: 26),
          Text(
            title,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
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
    );
  }
}

class _HeroOrb extends StatelessWidget {
  final IconData icon;

  const _HeroOrb({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF4F8CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.36),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, size: 42, color: Colors.white),
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
