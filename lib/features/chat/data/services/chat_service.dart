import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// Chat Service - Manages chat conversations with SharedPreferences persistence
class ChatService {
  static const String _chatsKey = 'chats_list';
  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get all chats
  Future<List<ChatModel>> getChats() async {
    await init();
    final chatsJson = _prefs?.getStringList(_chatsKey) ?? [];
    final chats = chatsJson
        .map((json) => ChatModel.fromJson(jsonDecode(json)))
        .toList();
    // Sort by lastMessageTime in descending order (newest first)
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return chats;
  }

  /// Add or update a chat
  Future<void> saveChat(ChatModel chat) async {
    await init();
    final chats = await getChats();

    // Check if chat already exists
    final existingIndex = chats.indexWhere((c) => c.id == chat.id);

    if (existingIndex != -1) {
      // Update existing chat
      chats[existingIndex] = chat;
    } else {
      // Add new chat
      chats.insert(0, chat); // Add at beginning for newest first
    }

    // Save to SharedPreferences
    final chatsJson = chats.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs?.setStringList(_chatsKey, chatsJson);
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    await init();
    final chats = await getChats();
    chats.removeWhere((c) => c.id == chatId);

    final chatsJson = chats.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs?.setStringList(_chatsKey, chatsJson);
  }

  /// Clear all chats
  Future<void> clearAllChats() async {
    await init();
    await _prefs?.remove(_chatsKey);
  }

  /// Check if chat exists
  Future<bool> chatExists(String chatId) async {
    await init();
    final chats = await getChats();
    return chats.any((c) => c.id == chatId);
  }

  /// Save messages for a chat
  Future<void> saveMessages(
    String chatId,
    List<Map<String, dynamic>> messages,
  ) async {
    await init();
    final messagesJson = messages.map((m) => jsonEncode(m)).toList();
    await _prefs?.setStringList('chat_messages_$chatId', messagesJson);
  }

  /// Get messages for a chat
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    await init();
    final messagesJson = _prefs?.getStringList('chat_messages_$chatId') ?? [];
    return messagesJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }
}
