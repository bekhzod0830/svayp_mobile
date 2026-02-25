import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// Chat Service - Manages chat conversations via REST API
class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  /// Get all chats (paginated)
  /// GET /api/v1/chats?page=0&size=10
  Future<List<ChatResponse>> getChats({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.get(
        '/chats',
        queryParameters: {'page': page, 'size': size},
      );

      print('📱 [ChatService] Get chats RAW response: ${response.data}');
      print('📱 [ChatService] Response type: ${response.data.runtimeType}');

      // Handle different response formats
      List<dynamic> items = [];

      if (response.data is List) {
        // Direct array response
        items = response.data as List<dynamic>;
        print(
          '📱 [ChatService] Response is direct array with ${items.length} items',
        );
      } else if (response.data is Map) {
        final map = response.data as Map<String, dynamic>;

        // Try nested data.data structure (most common)
        if (map.containsKey('data')) {
          final data = map['data'];
          if (data is Map && data.containsKey('data')) {
            items = data['data'] as List<dynamic>? ?? [];
            print('📱 [ChatService] Found data in data.data: ${items.length}');
          } else if (data is Map && data.containsKey('items')) {
            items = data['items'] as List<dynamic>? ?? [];
            print(
              '📱 [ChatService] Found items in data.items: ${items.length}',
            );
          } else if (data is List) {
            items = data;
            print('📱 [ChatService] Found array in data: ${items.length}');
          }
        }
        // Try direct items key
        else if (map.containsKey('items')) {
          items = map['items'] as List<dynamic>? ?? [];
          print('📱 [ChatService] Found items directly: ${items.length}');
        }
        // Try content key (Spring Boot Page format)
        else if (map.containsKey('content')) {
          items = map['content'] as List<dynamic>? ?? [];
          print(
            '📱 [ChatService] Found content (Spring Boot Page): ${items.length}',
          );
        }
      }

      print('📱 [ChatService] Parsing ${items.length} chat items');

      return items
          .map((item) => ChatResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error fetching chats: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get single conversation
  /// GET /api/v1/chats/{id}
  Future<ChatResponse> getChat(String chatId) async {
    try {
      final response = await _apiClient.get('/chats/$chatId');

      print('📱 [ChatService] Get chat response: ${response.data}');

      // Handle nested data structure
      final map = response.data as Map<String, dynamic>;
      final data =
          map['data'] is Map && (map['data'] as Map).containsKey('data')
          ? (map['data'] as Map)['data']
          : map['data'] ?? response.data;

      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error fetching chat: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get messages for a chat (paginated, newest first)
  /// GET /api/v1/chats/{id}/messages?page=0&size=20
  Future<List<ChatMessageResponse>> getMessages(
    String chatId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chats/$chatId/messages',
        queryParameters: {'page': page, 'size': size},
      );

      print('💬 [ChatService] Get messages RAW response: ${response.data}');
      print('💬 [ChatService] Response type: ${response.data.runtimeType}');

      // Handle different response formats (same as getChats)
      List<dynamic> items = [];

      if (response.data is List) {
        items = response.data as List<dynamic>;
        print(
          '💬 [ChatService] Response is direct array with ${items.length} messages',
        );
      } else if (response.data is Map) {
        final map = response.data as Map<String, dynamic>;

        // Try nested data.data structure (most common)
        if (map.containsKey('data')) {
          final data = map['data'];
          if (data is Map && data.containsKey('data')) {
            items = data['data'] as List<dynamic>? ?? [];
            print(
              '💬 [ChatService] Found data in data.data: ${items.length} messages',
            );
          } else if (data is Map && data.containsKey('items')) {
            items = data['items'] as List<dynamic>? ?? [];
            print(
              '💬 [ChatService] Found items in data.items: ${items.length} messages',
            );
          } else if (data is List) {
            items = data;
            print(
              '💬 [ChatService] Found array in data: ${items.length} messages',
            );
          }
        }
        // Try direct items key
        else if (map.containsKey('items')) {
          items = map['items'] as List<dynamic>? ?? [];
          print(
            '💬 [ChatService] Found items directly: ${items.length} messages',
          );
        }
        // Try content key (Spring Boot Page format)
        else if (map.containsKey('content')) {
          items = map['content'] as List<dynamic>? ?? [];
          print('💬 [ChatService] Found content: ${items.length} messages');
        }
      }

      print('💬 [ChatService] Parsing ${items.length} message items');

      return items
          .map(
            (item) =>
                ChatMessageResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error fetching messages: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create/reuse conversation ("Check Availability")
  /// POST /api/v1/chats
  Future<ChatResponse> createChat(CreateChatRequest request) async {
    try {
      print('💬 [ChatService] Creating chat with request: ${request.toJson()}');

      final response = await _apiClient.post('/chats', data: request.toJson());

      print('✅ [ChatService] Create chat response: ${response.data}');

      // Handle nested data structure
      final map = response.data as Map<String, dynamic>;
      final data =
          map['data'] is Map && (map['data'] as Map).containsKey('data')
          ? (map['data'] as Map)['data']
          : map['data'] ?? response.data;

      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error creating chat: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send message
  /// POST /api/v1/chats/{id}/messages
  Future<ChatMessageResponse> sendMessage(
    String chatId,
    SendMessageRequest request,
  ) async {
    try {
      print('💬 [ChatService] Sending message: ${request.toJson()}');

      final response = await _apiClient.post(
        '/chats/$chatId/messages',
        data: request.toJson(),
      );

      print('✅ [ChatService] Send message response: ${response.data}');

      // Handle nested data structure
      final map = response.data as Map<String, dynamic>;
      final data =
          map['data'] is Map && (map['data'] as Map).containsKey('data')
          ? (map['data'] as Map)['data']
          : map['data'] ?? response.data;

      return ChatMessageResponse.fromJson(data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error sending message: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mark messages as read
  /// POST /api/v1/chats/{id}/read
  Future<void> markAsRead(String chatId) async {
    try {
      await _apiClient.post('/chats/$chatId/read');
      print('✅ [ChatService] Marked chat $chatId as read');
    } catch (e) {
      print('❌ [ChatService] Error marking as read: $e');
      rethrow;
    }
  }

  /// Archive conversation
  /// POST /api/v1/chats/{id}/archive
  Future<void> archiveChat(String chatId) async {
    try {
      await _apiClient.post('/chats/$chatId/archive');
      print('✅ [ChatService] Archived chat $chatId');
    } catch (e) {
      print('❌ [ChatService] Error archiving chat: $e');
      rethrow;
    }
  }

  /// Get total unread count
  /// GET /api/v1/chats/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/chats/unread-count');

      print('🔔 [ChatService] Unread count response: ${response.data}');

      final data = response.data['data'] ?? response.data;
      return data['count'] as int? ?? data['unreadCount'] as int? ?? 0;
    } catch (e) {
      print('❌ [ChatService] Error fetching unread count: $e');
      return 0; // Return 0 on error instead of throwing
    }
  }
}
