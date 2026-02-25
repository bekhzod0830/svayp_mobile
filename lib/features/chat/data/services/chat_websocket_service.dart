import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// WebSocket Service for real-time chat messaging
/// Connects to: wss://app.svaypai.com/ws/chats/{chatId}
class ChatWebSocketService {
  WebSocketChannel? _channel;
  late final StreamController<ChatMessageResponse> _messageController;
  String? _currentChatId;
  String? _authToken;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  ChatWebSocketService() {
    // Create the stream controller once during initialization
    _messageController = StreamController<ChatMessageResponse>.broadcast();
  }

  /// Stream of incoming messages
  Stream<ChatMessageResponse> get messageStream => _messageController.stream;

  /// Check if WebSocket is connected
  bool get isConnected => _channel != null && !_isDisposed;

  /// Connect to chat WebSocket
  Future<void> connect(String chatId, String authToken) async {
    if (_isConnecting || _isDisposed) return;
    if (_currentChatId == chatId && isConnected) return;

    _isConnecting = true;
    _currentChatId = chatId;
    _authToken = authToken;

    try {
      // Close existing connection if any
      await disconnect();

      // Build WebSocket URL - construct wss:// URL directly
      const wsBaseUrl = 'wss://app.svaypai.com';
      final wsUrl = '$wsBaseUrl/ws/chats/$chatId';

      // Connect to WebSocket with token as query parameter
      final uri = Uri.parse(
        wsUrl,
      ).replace(queryParameters: {'token': authToken});

      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();

      _reconnectAttempts = 0;
      _isConnecting = false;
    } catch (e) {
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  /// Handle incoming messages
  void _onMessage(dynamic data) {
    try {

      final jsonData = json.decode(data as String);
      final message = ChatMessageResponse.fromJson(jsonData);

      _messageController.add(message);
    } catch (e) {
    }
  }

  /// Handle WebSocket errors
  void _onError(Object error, [StackTrace? stackTrace]) {
    if (stackTrace != null) {
    }
    _scheduleReconnect();
  }

  /// Handle WebSocket connection closed
  void _onDone() {
    _scheduleReconnect();
  }

  /// Send a message through WebSocket
  Future<void> sendMessage(SendMessageRequest request) async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    try {
      final data = json.encode(request.toJson());
      _channel?.sink.add(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (isConnected) {
        try {
          _channel?.sink.add(json.encode({'type': 'ping'}));
        } catch (e) {
        }
      }
    });
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectTimer?.isActive == true) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed && _currentChatId != null && _authToken != null) {
        connect(_currentChatId!, _authToken!);
      }
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {

    _pingTimer?.cancel();
    _pingTimer = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
    }

    _channel = null;
    _currentChatId = null;
    _authToken = null;
    _reconnectAttempts = 0;

  }

  /// Dispose the service
  Future<void> dispose() async {
    _isDisposed = true;

    await disconnect();

    await _messageController.close();

  }
}
