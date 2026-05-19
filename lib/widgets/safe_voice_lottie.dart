import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SafeVoiceLottie extends StatelessWidget {
  static const assetPath = 'assets/lottie/bridgecall_voice.json';

  final double height;

  const SafeVoiceLottie({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Lottie.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        repeat: true,
        frameRate: FrameRate.max,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) =>
            const _VoiceWaveFallback(),
      ),
    );
  }
}

class _VoiceWaveFallback extends StatelessWidget {
  const _VoiceWaveFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(17, (index) {
          final distance = (index - 8).abs();
          final height = 34.0 + ((8 - distance) * 9.0);
          return Container(
            width: 7,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFF4F8CFF), Color(0xFF8B5CF6)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          );
        }),
      ),
    );
  }
}
