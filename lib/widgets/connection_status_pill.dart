import 'package:flutter/material.dart';

import '../services/reliable_web_socket.dart';

class ConnectionStatusPill extends StatelessWidget {
  final BridgeSocketStatus status;

  const ConnectionStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BridgeSocketStatus.connected => const Color(0xFF22C55E),
      BridgeSocketStatus.connecting ||
      BridgeSocketStatus.reconnecting => const Color(0xFFFBBF24),
      BridgeSocketStatus.disconnected => const Color(0xFFFF4D4F),
      BridgeSocketStatus.idle => Colors.white54,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
