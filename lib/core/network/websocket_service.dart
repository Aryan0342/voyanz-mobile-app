import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/storage/token_storage.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

typedef WebSocketEventHandler = void Function(Map<String, dynamic> event);

class WebSocketService {
  final TokenStorage _tokenStorage;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatWatchdog;
  bool _disposed = true;
  bool _appActive = true;

  int _reconnectAttempt = 0;
  static const List<Duration> _backoffDurations = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 10),
  ];

  final Map<String, List<WebSocketEventHandler>> _listeners = {};

  WebSocketService(this._tokenStorage);

  Future<void> connect() async {
    if (_channel != null) return;
    _disposed = false;
    if (!_appActive) {
      _logger.i('WebSocket: app inactive, deferring connect');
      return;
    }

    try {
      final token = await _tokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        _logger.w('WebSocket: no access token available');
        _disposed = true;
        return;
      }

      // If an explicit websocketUrl is set in EnvConfig, prefer it.
      final explicit = EnvConfig.current.websocketUrl;
      Uri? connectedUri;

      if (explicit != null && explicit.isNotEmpty) {
        try {
          _logger.i('WebSocket: connecting to explicit websocketUrl $explicit');
          final uri = Uri.parse(explicit);
          _channel = WebSocketChannel.connect(uri);
          connectedUri = uri;
        } catch (e) {
          _logger.w('WebSocket: explicit websocketUrl failed: $e');
          _channel = null;
        }
      }

      if (_channel == null) {
        // Fallback candidates (try common paths and ports)
        final base = EnvConfig.current.baseUrl;
        final wsCandidates = <String>[
          base
              .replaceFirst('https://', 'wss://')
              .replaceFirst('http://', 'ws://'),
          base
                  .replaceFirst('https://', 'wss://')
                  .replaceFirst('http://', 'ws://') +
              '/ws',
          base
                  .replaceFirst('https://', 'wss://')
                  .replaceFirst('http://', 'ws://') +
              '/socket',
          base
                  .replaceFirst('https://', 'wss://')
                  .replaceFirst('http://', 'ws://') +
              ':5277',
        ];

        for (final candidate in wsCandidates) {
          try {
            _logger.i('WebSocket: trying $candidate');
            final uri = Uri.parse(candidate);
            final channel = WebSocketChannel.connect(uri);
            _channel = channel;
            connectedUri = uri;
            break;
          } catch (e) {
            _logger.w('WebSocket: connect attempt failed for $candidate: $e');
          }
        }
      }

      if (_channel == null) {
        throw Exception('WebSocket: could not connect to any candidate URI');
      }

      _logger.i('WebSocket: connected to ${connectedUri ?? "<unknown>"}');

      // Send join immediately
      _channel!.sink.add(
        jsonEncode({'action': 'join', 'token': token, 'group': ''}),
      );

      _reconnectAttempt = 0;
      _logger.i('WebSocket: join sent');

      // Listen for messages
      final connectedChannel = _channel!;
      connectedChannel.stream.listen(
        (raw) => _onMessage(raw, connectedChannel),
        onError: (err) => _onError(err, connectedChannel),
        onDone: () => _onDone(connectedChannel),
      );

      // Start heartbeat watchdog
      _startHeartbeatWatchdog();
    } catch (e) {
      _logger.e('WebSocket: connection error: $e');
      final channel = _channel;
      _channel = null;
      try {
        channel?.sink.close();
      } catch (_) {}
      _scheduleReconnect();
    }
  }

  void _startHeartbeatWatchdog() {
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = Timer(const Duration(seconds: 30), () {
      _logger.w('WebSocket: no message for 30s, reconnecting');
      _reconnectNow();
    });
  }

  void _reconnectNow() {
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    final channel = _channel;
    _channel = null;
    try {
      channel?.sink.close();
    } catch (_) {}
    if (!_disposed && _appActive) {
      connect();
    }
  }

  void _onMessage(dynamic raw, WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;

    try {
      _heartbeatWatchdog?.cancel();
      _startHeartbeatWatchdog();

      if (raw is! String) return;
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final action = msg['action'] as String?;

      _logger.d('WebSocket: received $action');

      if (action != null) {
        final handlers = _listeners[action] ?? [];
        for (final handler in handlers) {
          try {
            handler(msg);
          } catch (e) {
            _logger.e('WebSocket: handler error for $action: $e');
          }
        }
      }
    } catch (e) {
      _logger.e('WebSocket: message parse error: $e');
    }
  }

  void _onError(dynamic err, WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;

    _logger.e('WebSocket: error: $err');
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _channel = null;
    try {
      channel.sink.close();
    } catch (_) {}
    _scheduleReconnect();
  }

  void _onDone(WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;

    _logger.w('WebSocket: closed');
    _channel = null;
    if (!_disposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_appActive || _reconnectTimer != null) return;

    final idx = _reconnectAttempt < _backoffDurations.length - 1
        ? _reconnectAttempt
        : _backoffDurations.length - 1;
    final delay = _backoffDurations[idx];

    _logger.i('WebSocket: reconnect in ${delay.inMilliseconds}ms');
    _reconnectAttempt++;

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_disposed && _appActive) {
        connect();
      }
    });
  }

  void send(String action, Map<String, dynamic> data) {
    _sendPayload({'action': action, 'data': data}, action);
  }

  void ping() {
    _sendPayload(const {'action': 'ping'}, 'ping');
  }

  Future<void> sendWithToken(String action, Object data) async {
    final token = await _tokenStorage.accessToken;
    if (token == null || token.isEmpty) {
      _logger.w('WebSocket: no access token available, cannot send $action');
      return;
    }

    _sendPayload({'action': action, 'token': token, 'data': data}, action);
  }

  void _sendPayload(Map<String, dynamic> payload, String action) {
    if (_channel == null) {
      _logger.w('WebSocket: not connected, cannot send $action');
      return;
    }

    try {
      final msg = jsonEncode(payload);
      _channel!.sink.add(msg);
      _logger.d('WebSocket: sent $action');
    } catch (e) {
      _logger.e('WebSocket: send error: $e');
    }
  }

  void on(String action, WebSocketEventHandler handler) {
    _listeners.putIfAbsent(action, () => []).add(handler);
  }

  void off(String action, WebSocketEventHandler handler) {
    _listeners[action]?.remove(handler);
  }

  void setAppActive(bool active) {
    if (_appActive == active) return;

    _appActive = active;
    if (!active) {
      _logger.i('WebSocket: app inactive, closing socket');
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _heartbeatWatchdog?.cancel();
      _heartbeatWatchdog = null;

      final channel = _channel;
      _channel = null;
      try {
        channel?.sink.close();
      } catch (_) {}
      return;
    }

    if (!_disposed) {
      unawaited(connect());
    }
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _channel != null;
}
