import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// STOMP WebSocket Service for real-time chat messaging.
///
/// Transport: SockJS over STOMP
/// URL: https://app.svaypai.com/ws/chat
/// Auth: Bearer JWT in STOMP CONNECT headers
class ChatWebSocketService {
  StompClient? _stompClient;
  String? _activeChatId;
  String? _otherUserId;
  bool _isDisposed = false;
  bool _isConnecting = false;

  // Subscription handles
  StompUnsubscribe? _messageSub;
  StompUnsubscribe? _typingSub;
  StompUnsubscribe? _readSub;
  StompUnsubscribe? _presenceSub;

  // List-mode subscriptions (chat-list screen — one per chat room)
  final Map<String, StompUnsubscribe> _listSubs = {};
  Set<String> _listChatIds = {};

  // Stream controllers
  final _messageController = StreamController<ChatMessageResponse>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<PresenceResponse>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _listMessageController =
      StreamController<
        ({String chatId, ChatMessageResponse message})
      >.broadcast();

  /// Global unread message count for the bottom-nav badge.
  /// Increment from outside when a new message arrives on a non-active tab;
  /// reset to 0 when the user opens the chat list.
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);

  static const String _wsUrl = 'https://app.svaypai.com/ws/chat';

  // ── Public streams ───────────────────────────────────────────────────────

  /// New incoming messages for the current chat room.
  Stream<ChatMessageResponse> get messageStream => _messageController.stream;

  /// Typing events: { userId, chatId, isTyping }
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  /// Read receipts: { readBy, chatId }
  Stream<Map<String, dynamic>> get readStream => _readController.stream;

  /// Online/offline presence updates for the other party.
  Stream<PresenceResponse> get presenceStream => _presenceController.stream;

  /// True while the STOMP session is active and connected.
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Tagged messages for any list-mode subscribed chat room.
  Stream<({String chatId, ChatMessageResponse message})>
  get listMessageStream => _listMessageController.stream;

  /// The chatId currently open in the detail screen (null if none).
  String? get activeChatId => _activeChatId;

  bool get isConnected => _stompClient?.connected ?? false;

  // ── Connection management ────────────────────────────────────────────────

  /// Connect to the STOMP server using SockJS transport.
  /// Call [openChat] to subscribe to a specific room after connecting.
  void connect(String jwtToken) {
    if (_isDisposed || _isConnecting || isConnected) return;
    _isConnecting = true;
    debugPrint('[STOMP] Connecting to $_wsUrl ...');

    final authHeaders = {'Authorization': 'Bearer $jwtToken'};

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _wsUrl,
        onConnect: _onConnected,
        onDisconnect: (_) {
          debugPrint('[STOMP] Disconnected');
          _isConnecting = false;
          _connectionStateController.add(false);
        },
        onStompError: (frame) {
          debugPrint('[STOMP] STOMP error: ${frame.body}');
          _isConnecting = false;
          _connectionStateController.add(false);
        },
        onWebSocketError: (error) {
          debugPrint('[STOMP] WebSocket error: $error');
          _isConnecting = false;
          _connectionStateController.add(false);
        },
        stompConnectHeaders: authHeaders,
        webSocketConnectHeaders: authHeaders,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    _stompClient!.activate();
  }

  /// Open/switch to a chat room. Unsubscribes from the previous room first.
  /// Re-subscribes immediately if already connected; otherwise [_onConnected]
  /// will subscribe once the session is established.
  void openChat(String chatId, String otherUserId) {
    _unsubscribeAll();
    _activeChatId = chatId;
    _otherUserId = otherUserId.isNotEmpty ? otherUserId : null;
    debugPrint('[STOMP] openChat chatId=$chatId otherUserId="$otherUserId"');
    if (isConnected) {
      _subscribeToChat(chatId);
      if (_otherUserId != null) _subscribeToPresence(_otherUserId!);
    }
  }

  // ── STOMP callbacks ──────────────────────────────────────────────────────

  void _onConnected(StompFrame frame) {
    _isConnecting = false;
    _connectionStateController.add(true);
    final userName = frame.headers['user-name'];
    debugPrint('[STOMP] Connected as: $userName');

    if (_activeChatId != null) _subscribeToChat(_activeChatId!);
    if (_otherUserId != null && _otherUserId!.isNotEmpty)
      _subscribeToPresence(_otherUserId!);
    // Re-subscribe list-mode chats (chat list screen)
    for (final id in _listChatIds) _subscribeToListChat(id);
  }

  void _subscribeToChat(String chatId) {
    debugPrint('[STOMP] Subscribing to /topic/chat/$chatId');

    // 1. New messages
    _messageSub = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId',
      callback: (frame) {
        debugPrint(
          '[STOMP] ▼ RAW frame on /topic/chat/$chatId | body: ${frame.body}',
        );
        if (_isDisposed) {
          debugPrint('[STOMP] Dropped — service is disposed');
          return;
        }
        if (frame.body == null) {
          debugPrint('[STOMP] Dropped — frame body is null');
          return;
        }
        try {
          final data = json.decode(frame.body!) as Map<String, dynamic>;
          final msg = ChatMessageResponse.fromJson(data);
          debugPrint(
            '[STOMP] ✔ Parsed message id=${msg.id} from=${msg.senderId} content="${msg.content}"',
          );
          _messageController.add(msg);
          debugPrint('[STOMP] ✔ Message pushed to messageStream');
        } catch (e, st) {
          debugPrint('[STOMP] ✘ Failed to parse message: $e\n$st');
        }
      },
    );

    // 2. Typing indicator
    debugPrint('[STOMP] Subscribing to /topic/chat/$chatId/typing');
    _typingSub = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId/typing',
      callback: (frame) {
        debugPrint('[STOMP] ▼ Typing frame | body: ${frame.body}');
        if (frame.body == null || _isDisposed) return;
        try {
          _typingController.add(
            json.decode(frame.body!) as Map<String, dynamic>,
          );
        } catch (e) {
          debugPrint('[STOMP] ✘ Failed to parse typing: $e');
        }
      },
    );

    // 3. Read receipts
    debugPrint('[STOMP] Subscribing to /topic/chat/$chatId/read');
    _readSub = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId/read',
      callback: (frame) {
        debugPrint('[STOMP] ▼ Read-receipt frame | body: ${frame.body}');
        if (frame.body == null || _isDisposed) return;
        try {
          _readController.add(json.decode(frame.body!) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('[STOMP] ✘ Failed to parse read-receipt: $e');
        }
      },
    );
  }

  void _subscribeToPresence(String userId) {
    debugPrint('[STOMP] Subscribing to /topic/user/$userId/presence');
    _presenceSub = _stompClient!.subscribe(
      destination: '/topic/user/$userId/presence',
      callback: (frame) {
        debugPrint('[STOMP] ▼ Presence frame | body: ${frame.body}');
        if (frame.body == null || _isDisposed) return;
        try {
          final presence = PresenceResponse.fromJson(
            json.decode(frame.body!) as Map<String, dynamic>,
          );
          debugPrint(
            '[STOMP] ✔ Presence update userId=${presence.userId} online=${presence.online}',
          );
          _presenceController.add(presence);
        } catch (e) {
          debugPrint('[STOMP] ✘ Failed to parse presence: $e');
        }
      },
    );
  }

  // ── List-mode helpers ────────────────────────────────────────────────────

  /// Subscribe to all [chatIds] so the chat list receives live message previews.
  void openList(List<String> chatIds) {
    _closeListSubs();
    _listChatIds = chatIds.toSet();
    debugPrint('[STOMP] openList: ${_listChatIds.length} chat(s)');
    if (isConnected) {
      for (final id in _listChatIds) _subscribeToListChat(id);
    }
  }

  /// Dynamically subscribe to a single [chatId] without disturbing existing
  /// subscriptions. Call when a new chat is created after [openList] was
  /// already called (e.g. a buyer starts a conversation with a seller).
  /// Returns [true] if the chatId was newly added, [false] if already known.
  bool addChatToList(String chatId) {
    if (_listChatIds.contains(chatId)) return false;
    _listChatIds.add(chatId);
    debugPrint(
      '[STOMP] addChatToList: $chatId (now ${_listChatIds.length} chats)',
    );
    if (isConnected) _subscribeToListChat(chatId);
    return true;
  }

  /// Unsubscribe from all list-mode topics.
  void closeList() {
    _closeListSubs();
    _listChatIds = {};
  }

  void _closeListSubs() {
    for (final unsub in _listSubs.values) {
      try {
        unsub();
      } catch (_) {}
    }
    _listSubs.clear();
  }

  void _subscribeToListChat(String chatId) {
    if (_listSubs.containsKey(chatId)) return;
    debugPrint('[STOMP] List-subscribing /topic/chat/$chatId');
    _listSubs[chatId] = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId',
      callback: (frame) {
        if (frame.body == null || _isDisposed) return;
        try {
          final msg = ChatMessageResponse.fromJson(
            json.decode(frame.body!) as Map<String, dynamic>,
          );
          debugPrint('[STOMP] ✔ List msg chatId=$chatId id=${msg.id}');
          _listMessageController.add((chatId: chatId, message: msg));
        } catch (e) {
          debugPrint('[STOMP] ✘ List msg parse failed chatId=$chatId: $e');
        }
      },
    );
  }

  // ── Send actions ─────────────────────────────────────────────────────────

  /// Send a text message via WebSocket (preferred over REST).
  void sendMessage(String content, {String type = 'TEXT'}) {
    if (_activeChatId == null || !isConnected) return;
    _stompClient!.send(
      destination: '/app/chat/$_activeChatId/send',
      body: json.encode({'content': content, 'type': type}),
    );
  }

  /// Notify the other party that the current user is typing.
  /// Call from a throttled [TextField.onChanged] handler.
  void sendTyping() {
    if (_activeChatId == null || !isConnected) return;
    _stompClient!.send(
      destination: '/app/chat/$_activeChatId/typing',
      body: '',
    );
  }

  /// Mark all messages in the current chat as read via WebSocket.
  void markAsRead() {
    if (_activeChatId == null || !isConnected) return;
    _stompClient!.send(destination: '/app/chat/$_activeChatId/read', body: '');
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Unsubscribe from the current chat room without disconnecting.
  void closeChat() {
    _unsubscribeAll();
    _activeChatId = null;
    _otherUserId = null;
  }

  /// Disconnect from the STOMP server. Can be reconnected later.
  Future<void> disconnect() async {
    _closeListSubs();
    _unsubscribeAll();
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;
    _isConnecting = false;
  }

  /// Permanently dispose the service and close all streams.
  Future<void> dispose() async {
    _isDisposed = true;
    await disconnect();
    await _messageController.close();
    await _typingController.close();
    await _readController.close();
    await _presenceController.close();
    await _connectionStateController.close();
    await _listMessageController.close();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _unsubscribeAll() {
    try {
      _messageSub?.call();
    } catch (_) {}
    try {
      _typingSub?.call();
    } catch (_) {}
    try {
      _readSub?.call();
    } catch (_) {}
    try {
      _presenceSub?.call();
    } catch (_) {}
    _messageSub = null;
    _typingSub = null;
    _readSub = null;
    _presenceSub = null;
  }
}
