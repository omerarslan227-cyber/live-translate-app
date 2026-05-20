import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/app_logger.dart';

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
  final void Function(String reason)? onDisconnected;
  final Duration heartbeatInterval;
  final Duration heartbeatTimeout;
  final Duration maxReconnectDelay;
  final bool heartbeatEnabled;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _closedByUser = false;
  bool _hasConnectedOnce = false;
  int _attempt = 0;
  BridgeSocketStatus _status = BridgeSocketStatus.idle;
  DateTime? _lastMessageAt;

  ReliableWebSocketClient({
    required this.uri,
    required this.name,
    required this.onMessage,
    this.onError,
    this.onStatus,
    this.onReconnected,
    this.onDisconnected,
    this.heartbeatInterval = const Duration(seconds: 18),
    this.heartbeatTimeout = const Duration(seconds: 12),
    this.maxReconnectDelay = const Duration(seconds: 20),
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
      AppLogger.info('socket', 'connecting', {
        'name': name,
        'uri': _safeUriForLogs(uri),
        'attempt': _attempt + 1,
      });
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          AppLogger.error('socket', 'stream error', {'name': name}, error);
          onError?.call(error);
          _scheduleReconnect('stream_error');
        },
        onDone: () => _scheduleReconnect('stream_done'),
        cancelOnError: true,
      );
      _attempt = 0;
      _lastMessageAt = DateTime.now();
      final wasReconnect = _hasConnectedOnce;
      _hasConnectedOnce = true;
      _setStatus(BridgeSocketStatus.connected);
      if (wasReconnect) onReconnected?.call();
      _startHeartbeat();
    } catch (error) {
      AppLogger.error('socket', 'connect failed', {'name': name}, error);
      onError?.call(error);
      _scheduleReconnect('connect_exception');
    }
  }

  void sendJson(Map<String, dynamic> payload) {
    sendText(jsonEncode(payload));
  }

  void sendBinary(List<int> payload) {
    try {
      _channel?.sink.add(payload);
    } catch (error) {
      AppLogger.error('socket', 'binary send failed', {'name': name}, error);
      onError?.call(error);
      _scheduleReconnect('send_binary_exception');
    }
  }

  void sendText(String payload) {
    try {
      _channel?.sink.add(payload);
    } catch (error) {
      AppLogger.error('socket', 'send failed', {'name': name}, error);
      onError?.call(error);
      _scheduleReconnect('send_exception');
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
          _lastMessageAt = DateTime.now();
          return;
        }
      } catch (_) {}
    }
    _lastMessageAt = DateTime.now();
    onMessage(message);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!heartbeatEnabled) return;
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      final lastMessageAt = _lastMessageAt;
      if (lastMessageAt != null &&
          DateTime.now().difference(lastMessageAt) >
              heartbeatInterval + heartbeatTimeout) {
        AppLogger.warn('socket', 'heartbeat timeout', {
          'name': name,
          'lastMessageAt': lastMessageAt.toIso8601String(),
        });
        _scheduleReconnect('heartbeat_timeout');
        return;
      }
      sendJson({'type': 'ping', 'client': name});
    });
  }

  void _scheduleReconnect([String reason = 'unknown']) {
    if (_closedByUser) return;
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    onDisconnected?.call(reason);
    _setStatus(
      _hasConnectedOnce
          ? BridgeSocketStatus.reconnecting
          : BridgeSocketStatus.disconnected,
    );
    _reconnectTimer?.cancel();
    final delay = _nextReconnectDelay();
    AppLogger.warn('socket', 'scheduled reconnect', {
      'name': name,
      'reason': reason,
      'attempt': _attempt + 1,
      'delayMs': delay.inMilliseconds,
    });
    _attempt += 1;
    _reconnectTimer = Timer(delay, connect);
  }

  Duration _nextReconnectDelay() {
    final exponentialSeconds = math.min(math.pow(2, _attempt).toInt(), 16);
    final jitterMs = math.Random().nextInt(350);
    final delay = Duration(seconds: exponentialSeconds, milliseconds: jitterMs);
    return delay > maxReconnectDelay ? maxReconnectDelay : delay;
  }

  void _setStatus(BridgeSocketStatus status) {
    if (_status == status) return;
    _status = status;
    onStatus?.call(status);
  }

  String _safeUriForLogs(Uri uri) {
    return uri.replace(query: '', userInfo: '').toString();
  }
}
