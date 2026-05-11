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
  String _source = 'Türkçe';
  String _target = 'İngilizce';

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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _OnboardingPage(
                    icon: Icons.translate_rounded,
                    title: 'Canlı çeviri görüşmesi',
                    body:
                        'BridgeCall konuşmayı algılar, çevirir ve karşı tarafa altyazı/ses olarak ulaştırır.',
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.language_rounded, size: 54),
                        const SizedBox(height: 20),
                        const Text(
                          'Dilini seç',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Varsayılan başlangıç Türkçe → İngilizce. Görüşme içinde her zaman değiştirebilirsin.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                        const SizedBox(height: 24),
                        _LanguagePicker(
                          label: 'Senin dilin',
                          value: _source,
                          onChanged: (value) => setState(() => _source = value),
                        ),
                        const SizedBox(height: 12),
                        _LanguagePicker(
                          label: 'Hedef dil',
                          value: _target,
                          onChanged: (value) => setState(() => _target = value),
                        ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    icon: Icons.mic_rounded,
                    title: 'Mikrofon izni',
                    body:
                        'Sesli çeviri için mikrofon gerekir. İzin yoksa uygulama çökmeden seni yönlendirir.',
                    actionLabel: 'Mikrofonu Aç',
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
                      duration: const Duration(milliseconds: 180),
                      width: _page == index ? 26 : 8,
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
                    ),
                    onPressed: _next,
                    child: Text(_page == 2 ? 'Başla' : 'Devam'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
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
          Icon(icon, size: 58),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
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
      initialValue: value,
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
