import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'constants.dart';

/// WebSocket connection to the Node.js backend.
/// Broadcasts real-time admin events (sync_complete, content_updated, etc.)
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  String? _currentToken;
  bool _disposed = false;

  final _controller = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get events => _controller.stream;

  void connect(String token) {
    _currentToken = token;
    _disposed = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _doConnect();
  }

  void _doConnect() {
    if (_disposed || _currentToken == null) return;
    try {
      final token = _currentToken?.trim();
      final uri = token == null || token.isEmpty || token == 'cookie-session'
          ? Uri.parse(ApiConstants.wsUrl)
          : Uri.parse('${ApiConstants.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      unawaited(
        _channel!.ready.catchError((_) {
          _scheduleReconnect();
        }),
      );
      _channel!.stream.listen(
        (raw) {
          try {
            final map = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(WsEvent.fromJson(map));
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) {
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _doConnect);
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

class WsEvent {
  final String type;
  final Map<String, dynamic> data;
  const WsEvent({required this.type, required this.data});

  factory WsEvent.fromJson(Map<String, dynamic> json) =>
      WsEvent(type: json['type'] as String? ?? 'unknown', data: json);
}
