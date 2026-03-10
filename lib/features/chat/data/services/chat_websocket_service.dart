import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// STOMP WebSocket Service for real-time chat messaging
/// Connects to: wss://app.svaypai.com/ws/chat
/// Protocol: STOMP with Authorization header
class ChatWebSocketService {
  StompClient? _stompClient;
  late final StreamController<ChatMessageResponse> _messageController;
  String? _currentChatId;
  bool _isDisposed = false;
  bool _isConnecting = false;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribeFn;
  List<Function({Map<String, String>? unsubscribeHeaders})?>  _extraUnsubs = [];
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  static const String _wsUrl = 'wss://app.svaypai.com/ws/chat';

  ChatWebSocketService() {
    _messageController = StreamController<ChatMessageResponse>.broadcast();
  }

  /// Stream of incoming messages
  Stream<ChatMessageResponse> get messageStream => _messageController.stream;

  /// Stream of connection state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Check if STOMP client is connected
  bool get isConnected => _stompClient?.connected ?? false;

  /// Connect to STOMP WebSocket and subscribe to a chat room
  Future<void> connect(String chatId, String authToken) async {
    if (_isDisposed || _isConnecting) return;
    if (_currentChatId == chatId && isConnected) return;

    _isConnecting = true;
    debugPrint('[STOMP] Connecting to $_wsUrl for chat $chatId ...');

    // Disconnect previous session if any
    await disconnect();

    _currentChatId = chatId;

    final authHeaders = {'Authorization': 'Bearer $authToken'};

    _stompClient = StompClient(
      config: StompConfig(
        url: _wsUrl,
        stompConnectHeaders: authHeaders,
        webSocketConnectHeaders: authHeaders,
        onConnect: _onConnect,
        onWebSocketError: (error) {
          debugPrint('[STOMP] WebSocket error: $error');
          _connectionStateController.add(false);
        },
        onStompError: (frame) {
          debugPrint('[STOMP] STOMP error: ${frame.body}');
          _connectionStateController.add(false);
        },
        onDisconnect: (_) {
          debugPrint('[STOMP] Disconnected');
          _connectionStateController.add(false);
        },
        onDebugMessage: (msg) {
          debugPrint('[STOMP] debug: $msg');
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    _stompClient!.activate();
    _isConnecting = false;
  }

  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribeFn2;
  Function({Map<String, String>? unsubscribeHeaders})? _unsubscribeFn3;

  /// Called when STOMP connection is established
  void _onConnect(StompFrame frame) {
    if (_currentChatId == null || _isDisposed) return;

    _connectionStateController.add(true);

    // Extract the user principal name from the CONNECTED frame header.
    // Spring Boot uses this to route user-specific messages.
    final userName = frame.headers['user-name'];
    debugPrint('[STOMP] Connected as user: $userName');

    // Subscribe to every plausible Spring Boot STOMP destination.
    // The one that prints "[STOMP] Frame arrived" is the correct one.
    final destinations = [
      '/topic/chat/$_currentChatId',
      '/topic/chats/$_currentChatId',
      '/user/queue/messages',
      '/user/queue/chat',
      // Explicit user-principal paths (Spring sends here when using convertAndSendToUser)
      if (userName != null) '/user/$userName/queue/messages',
      if (userName != null) '/user/$userName/queue/chat',
      if (userName != null) '/user/$userName/topic/chat/$_currentChatId',
    ];

    final fns = <Function({Map<String, String>? unsubscribeHeaders})?>[];
    for (final dest in destinations) {
      debugPrint('[STOMP] Subscribing to $dest');
      fns.add(_stompClient?.subscribe(destination: dest, callback: _onMessage));
    }
    _unsubscribeFn  = fns.isNotEmpty ? fns[0] : null;
    _unsubscribeFn2 = fns.length > 1  ? fns[1] : null;
    _unsubscribeFn3 = fns.length > 2  ? fns[2] : null;
    _extraUnsubs    = fns.length > 3  ? fns.sublist(3) : [];
  }

  /// Handle incoming STOMP message frame
  void _onMessage(StompFrame frame) {
    debugPrint('[STOMP] Frame arrived — destination: ${frame.headers['destination']}, body: ${frame.body}');

    if (frame.body == null || _isDisposed) return;

    try {
      final jsonData = json.decode(frame.body!);
      final message = ChatMessageResponse.fromJson(
        jsonData as Map<String, dynamic>,
      );
      _messageController.add(message);
    } catch (e) {
      debugPrint('[STOMP] Failed to parse message: $e\nRaw body: ${frame.body}');
    }
  }

  /// Disconnect from STOMP WebSocket
  Future<void> disconnect() async {
    // Unsubscribe from all topics
    try { _unsubscribeFn?.call(); } catch (_) {}
    try { _unsubscribeFn2?.call(); } catch (_) {}
    try { _unsubscribeFn3?.call(); } catch (_) {}
    for (final fn in _extraUnsubs) { try { fn?.call(); } catch (_) {} }
    _unsubscribeFn = null;
    _unsubscribeFn2 = null;
    _unsubscribeFn3 = null;
    _extraUnsubs = [];

    // Deactivate STOMP client
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;

    _currentChatId = null;
    _isConnecting = false;
  }

  /// Dispose the service permanently
  Future<void> dispose() async {
    _isDisposed = true;
    await disconnect();
    await _messageController.close();
    await _connectionStateController.close();
  }
}
