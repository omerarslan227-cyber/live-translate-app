import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class CaptionState {
  final String sourceText;
  final String translatedText;
  final bool isFinal;
  final bool degraded;

  const CaptionState({
    required this.sourceText,
    required this.translatedText,
    required this.isFinal,
    this.degraded = false,
  });

  static const empty = CaptionState(
    sourceText: '',
    translatedText: '',
    isFinal: true,
  );

  bool get hasText => sourceText.trim().isNotEmpty || translatedText.trim().isNotEmpty;
}

class SubtitleOverlay extends StatefulWidget {
  final ValueNotifier<CaptionState> captionNotifier;

  const SubtitleOverlay({
    super.key,
    required this.captionNotifier,
  });

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay> {
  static const _debounce = Duration(milliseconds: 80);

  CaptionState _visible = CaptionState.empty;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _visible = widget.captionNotifier.value;
    widget.captionNotifier.addListener(_scheduleUpdate);
  }

  @override
  void didUpdateWidget(covariant SubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.captionNotifier == widget.captionNotifier) return;
    oldWidget.captionNotifier.removeListener(_scheduleUpdate);
    _visible = widget.captionNotifier.value;
    widget.captionNotifier.addListener(_scheduleUpdate);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.captionNotifier.removeListener(_scheduleUpdate);
    super.dispose();
  }

  void _scheduleUpdate() {
    final next = widget.captionNotifier.value;
    if (next.isFinal) {
      _debounceTimer?.cancel();
      if (mounted) setState(() => _visible = next);
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) setState(() => _visible = widget.captionNotifier.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible.hasText) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom + 96;
    final textScale = media.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.25,
    );
    final direction = _looksRtl(_visible.translatedText)
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Positioned(
      left: 18,
      right: 18,
      bottom: bottom,
      child: RepaintBoundary(
        child: Directionality(
          textDirection: direction,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _CaptionTextBlock(
                      key: ValueKey(
                        '${_visible.isFinal}:${_visible.sourceText}:${_visible.translatedText}',
                      ),
                      caption: _visible,
                      textScale: textScale,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _looksRtl(String text) {
    return RegExp(r'[\u0590-\u08FF]').hasMatch(text);
  }
}

class _CaptionTextBlock extends StatelessWidget {
  final CaptionState caption;
  final TextScaler textScale;

  const _CaptionTextBlock({
    super.key,
    required this.caption,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    final primary = caption.translatedText.trim().isNotEmpty
        ? caption.translatedText.trim()
        : caption.sourceText.trim();
    final secondary = caption.translatedText.trim().isNotEmpty
        ? caption.sourceText.trim()
        : '';
    final opacity = caption.isFinal ? 1.0 : 0.76;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StrokedText(
            primary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontStyle: caption.isFinal ? FontStyle.normal : FontStyle.italic,
            maxLines: 2,
            textScale: textScale,
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 4),
            _StrokedText(
              secondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.78),
              maxLines: 1,
              textScale: textScale,
            ),
          ],
          if (caption.degraded) ...[
            const SizedBox(height: 4),
            Text(
              'Translation unavailable',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.64),
                fontSize: textScale.scale(11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StrokedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final Color color;
  final int maxLines;
  final TextScaler textScale;

  const _StrokedText(
    this.text, {
    required this.fontSize,
    required this.fontWeight,
    required this.maxLines,
    required this.textScale,
    this.fontStyle = FontStyle.normal,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final scaledSize = textScale.scale(fontSize);
    final baseStyle = TextStyle(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: 1.18,
      letterSpacing: 0,
    );

    return Stack(
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.fade,
          softWrap: true,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black.withValues(alpha: 0.86),
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.fade,
          softWrap: true,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(color: color),
        ),
      ],
    );
  }
}
