import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/features/chat/data/models/chat_cache_model.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// Chat Cache Service - Manages chat list caching with Hive persistence
class ChatCacheService {
  static const String _boxName = 'chat_cache_box';
  static const String _timestampKey = 'chat_cache_timestamp';
  static const Duration _cacheValidity = Duration(hours: 24);
  Box<ChatCacheModel>? _chatBox;

  /// Initialize the chat cache box
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _chatBox = await Hive.openBox<ChatCacheModel>(_boxName);
      } else {
        _chatBox = Hive.box<ChatCacheModel>(_boxName);
      }
    } catch (e) {
      // If there's an error (likely due to schema change), delete the old box and create new one
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _chatBox = await Hive.openBox<ChatCacheModel>(_boxName);
      } catch (deleteError) {
        // If deletion also fails, rethrow the original error
        rethrow;
      }
    }
  }

  /// Get all cached chats (sorted by last message time, newest first)
  /// Returns empty list and clears cache if older than 24 hours
  Future<List<ChatResponse>> getCachedChats() async {
    // Check expiry
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_timestampKey);
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheValidity) {
        await clearCache();
        return [];
      }
    } else {
      // No timestamp means old data with no expiry — treat as expired
      await clearCache();
      return [];
    }

    final cachedChats = _chatBox?.values.toList() ?? [];

    // Sort by lastMessageAt, newest first (null dates go to end)
    cachedChats.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return cachedChats.map((cache) => cache.toChatResponse()).toList();
  }

  int getCachedChatCount() {
    return _chatBox?.length ?? 0;
  }

  /// Check if a chat is cached
  bool isChatCached(String chatId) {
    return _chatBox?.values.any((chat) => chat.chatId == chatId) ?? false;
  }

  /// Get a single cached chat by ID
  Future<ChatResponse?> getCachedChat(String chatId) async {
    await init();
    final cache = _chatBox?.values
        .cast<ChatCacheModel?>()
        .firstWhere(
          (chat) => chat?.chatId == chatId,
          orElse: () => null,
        );
    return cache?.toChatResponse();
  }

  /// Save/update chats from API response
  Future<void> updateChatsCache(List<ChatResponse> chats) async {
    await init();

    // Clear existing cache
    await _chatBox?.clear();

    // Add all chats to cache
    for (final chat in chats) {
      final cacheModel = ChatCacheModel.fromChatResponse(chat);
      await _chatBox?.add(cacheModel);
    }

    // Save cache timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Update a single chat in cache
  Future<void> updateSingleChat(ChatResponse chat) async {
    await init();

    // Find existing chat by ID
    final existingIndex =
        _chatBox?.values.toList().indexWhere(
          (cache) => cache.chatId == chat.id,
        ) ??
        -1;

    if (existingIndex != -1) {
      // Update existing chat
      final updatedCache = ChatCacheModel.fromChatResponse(chat);
      await _chatBox?.putAt(existingIndex, updatedCache);
    } else {
      // Add new chat
      final cacheModel = ChatCacheModel.fromChatResponse(chat);
      await _chatBox?.add(cacheModel);
    }
  }

  /// Remove a chat from cache
  Future<void> removeChat(String chatId) async {
    await init();

    final existingIndex =
        _chatBox?.values.toList().indexWhere(
          (cache) => cache.chatId == chatId,
        ) ??
        -1;

    if (existingIndex != -1) {
      await _chatBox?.deleteAt(existingIndex);
    }
  }

  /// Clear all cached chats
  Future<void> clearCache() async {
    await init();
    await _chatBox?.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timestampKey);
  }

  /// Close the box
  Future<void> close() async {
    await _chatBox?.close();
  }
}
