/// Chat Model - Represents a conversation with a seller
class ChatModel {
  final String id;
  final String sellerName;
  final String sellerAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? productImage;
  final String? productName;
  final int? productPrice;
  final int? productOriginalPrice;

  ChatModel({
    required this.id,
    required this.sellerName,
    required this.sellerAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.productImage,
    this.productName,
    this.productPrice,
    this.productOriginalPrice,
  });

  /// Convert ChatModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'productImage': productImage,
      'productName': productName,
      'productPrice': productPrice,
      'productOriginalPrice': productOriginalPrice,
    };
  }

  /// Create ChatModel from JSON
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      sellerName: json['sellerName'] as String,
      sellerAvatar: json['sellerAvatar'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      productImage: json['productImage'] as String?,
      productName: json['productName'] as String?,
      productPrice: json['productPrice'] as int?,
      productOriginalPrice: json['productOriginalPrice'] as int?,
    );
  }

  /// Create a copy with updated fields
  ChatModel copyWith({
    String? id,
    String? sellerName,
    String? sellerAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? productImage,
    String? productName,
    int? productPrice,
    int? productOriginalPrice,
  }) {
    return ChatModel(
      id: id ?? this.id,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      productImage: productImage ?? this.productImage,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productOriginalPrice: productOriginalPrice ?? this.productOriginalPrice,
    );
  }
}
