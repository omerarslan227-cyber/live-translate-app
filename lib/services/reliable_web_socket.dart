import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum BridgeSocketStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
}

extension BridgeSocketStatusLabel on BridgeSocketStatus {
  String get label {
    switch (this) {
      case BridgeSocketStatus.idle:
        return 'Bekliyor';
      case BridgeSocketStatus.connecting:
        return 'Bağlanıyor';
      case BridgeSocketStatus.connected:
        return 'Bağlandı';
      case BridgeSocketStatus.reconnecting:
        return 'Yeniden bağlanıyor';
      case BridgeSocketStatus.disconnected:
        return 'Koptu';
    }
  }
}

class ReliableWebSocketClient {
  final Uri uri;
  final String name;
  final void Function(dynamic message) onMessage;
  final void Function(Object error)? onError;
  final void Function(BridgeSocketStatus status)? onStatus;
  final void Function()? onReconnected;
  final Duration heartbeatInterval;
  final bool heartbeatEnabled;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _closedByUser = false;
  bool _hasConnectedOnce = false;
  int _attempt = 0;
  BridgeSocketStatus _status = BridgeSocketStatus.idle;

  ReliableWebSocketClient({
    required this.uri,
    required this.name,
    required this.onMessage,
    this.onError,
    this.onStatus,
    this.onReconnected,
    this.heartbeatInterval = const Duration(seconds: 18),
    this.heartbeatEnabled = true,
  });

  BridgeSocketStatus get status => _status;
  bool get isConnected => _status == BridgeSocketStatus.connected;

  void connect() {
    if (_status == BridgeSocketStatus.connecting ||
        _status == BridgeSocketStatus.connected) {
      return;
    }
    _closedByUser = false;
    _setStatus(
      _hasConnectedOnce
          ? BridgeSocketStatus.reconnecting
          : BridgeSocketStatus.connecting,
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          onError?.call(error);
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _attempt = 0;
      final wasReconnect = _hasConnectedOnce;
      _hasConnectedOnce = true;
      _setStatus(BridgeSocketStatus.connected);
      if (wasReconnect) onReconnected?.call();
      _startHeartbeat();
    } catch (error) {
      onError?.call(error);
      _scheduleReconnect();
    }
  }

  void sendJson(Map<String, dynamic> payload) {
    sendText(jsonEncode(payload));
  }

  void sendText(String payload) {
    try {
      _channel?.sink.add(payload);
    } catch (error) {
      onError?.call(error);
      _scheduleReconnect();
    }
  }

  Future<void> close() async {
    _closedByUser = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _setStatus(BridgeSocketStatus.disconnected);
  }

  void _handleMessage(dynamic message) {
    if (message is String) {
      try {
        final data = jsonDecode(message);
        if (data is Map && data['type'] == 'pong') {
          return;
        }
      } catch (_) {}
    }
    onMessage(message);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!heartbeatEnabled) return;
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      sendJson({'type': 'ping', 'client': name});
    });
  }

  void _scheduleReconnect() {
    if (_closedByUser) return;
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _setStatus(
      _hasConnectedOnce
          ? BridgeSocketStatus.reconnecting
          : BridgeSocketStatus.disconnected,
    );
    _reconnectTimer?.cancel();
    final seconds = (_attempt + 1).clamp(1, 8);
    _attempt += 1;
    _reconnectTimer = Timer(Duration(seconds: seconds), connect);
  }

  void _setStatus(BridgeSocketStatus status) {
    if (_status == status) return;
    _status = status;
    onStatus?.call(status);
  }
}
