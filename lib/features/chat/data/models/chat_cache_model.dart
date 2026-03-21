import 'package:hive/hive.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

part 'chat_cache_model.g.dart';

/// Chat Cache Model for Hive Persistence
/// Stores minimal chat info for caching conversations
@HiveType(typeId: 4)
class ChatCacheModel extends HiveObject {
  @HiveField(0)
  late String chatId;

  @HiveField(1)
  late String sellerName;

  @HiveField(2)
  String? sellerLogo;

  @HiveField(3)
  String? userName;

  @HiveField(4)
  String? userAvatar;

  @HiveField(5)
  String? productTitle;

  @HiveField(6)
  String? productImage;

  @HiveField(7)
  String? lastMessagePreview;

  @HiveField(8)
  DateTime? lastMessageAt;

  @HiveField(9)
  late int unreadCount;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late String status; // 'active', 'archived', 'resolved'

  @HiveField(12)
  late String sellerId;

  @HiveField(13)
  String? userId;

  @HiveField(14)
  String? productId;

  ChatCacheModel({
    required this.chatId,
    required this.sellerName,
    this.sellerLogo,
    this.userName,
    this.userAvatar,
    this.productTitle,
    this.productImage,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    this.status = 'active',
    required this.sellerId,
    this.userId,
    this.productId,
  });

  /// Create cache model from API response
  factory ChatCacheModel.fromChatResponse(ChatResponse chat) {
    return ChatCacheModel(
      chatId: chat.id,
      sellerName: chat.sellerName,
      sellerLogo: chat.sellerLogo,
      userName: chat.userName,
      userAvatar: chat.userAvatar,
      productTitle: chat.productTitle,
      productImage: chat.productImage,
      lastMessagePreview: chat.lastMessagePreview,
      lastMessageAt: chat.lastMessageAt,
      unreadCount: chat.unreadCount,
      createdAt: chat.createdAt,
      status: chat.status.toString().split('.').last,
      sellerId: chat.sellerId,
      userId: chat.userId,
      productId: chat.productId,
    );
  }

  /// Convert to ChatResponse for UI consumption
  ChatResponse toChatResponse() {
    ChatStatus chatStatus;
    switch (status) {
      case 'archived':
        chatStatus = ChatStatus.archived;
        break;
      case 'resolved':
        chatStatus = ChatStatus.resolved;
        break;
      default:
        chatStatus = ChatStatus.active;
    }

    return ChatResponse(
      id: chatId,
      sellerName: sellerName,
      sellerLogo: sellerLogo,
      userName: userName,
      userAvatar: userAvatar,
      productTitle: productTitle,
      productImage: productImage,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      createdAt: createdAt,
      status: chatStatus,
      sellerId: sellerId,
      userId: userId,
      productId: productId,
    );
  }

  @override
  String toString() {
    return 'ChatCacheModel(chatId: $chatId, sellerName: $sellerName, lastMessage: $lastMessagePreview)';
  }
}
