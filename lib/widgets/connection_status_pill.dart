import 'package:flutter/material.dart';

import '../services/reliable_web_socket.dart';

class ConnectionStatusPill extends StatefulWidget {
  final BridgeSocketStatus status;

  const ConnectionStatusPill({super.key, required this.status});

  @override
  State<ConnectionStatusPill> createState() => _ConnectionStatusPillState();
}

class _ConnectionStatusPillState extends State<ConnectionStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.status) {
      BridgeSocketStatus.connected => const Color(0xFF22C55E),
      BridgeSocketStatus.connecting ||
      BridgeSocketStatus.reconnecting => const Color(0xFFFBBF24),
      BridgeSocketStatus.disconnected => const Color(0xFFFF4D4F),
      BridgeSocketStatus.idle => Colors.white54,
    };

    final isLive = widget.status == BridgeSocketStatus.connected;
    final isProblem =
        widget.status == BridgeSocketStatus.reconnecting ||
        widget.status == BridgeSocketStatus.disconnected;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = isProblem ? 0.20 + (_controller.value * 0.28) : 0.12;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: isLive ? 0.26 : 0.36),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: pulse),
                blurRadius: isProblem ? 18 : 10,
                spreadRadius: isProblem ? 1 : 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            widget.status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
