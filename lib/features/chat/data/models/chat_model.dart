import 'package:equatable/equatable.dart';

/// Chat Status Enum
enum ChatStatus { active, archived, resolved }

/// Message Type Enum
enum MessageType { text, image, file, product }

/// Sender Type Enum
enum SenderType { user, seller, admin }

/// Message Attachment Model
class MessageAttachment extends Equatable {
  final String id;
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int fileSize;

  const MessageAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    required this.fileSize,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  @override
  List<Object?> get props => [id, fileUrl, fileType, fileName, fileSize];
}

/// Chat Response Model (snake_case JSON from API)
class ChatResponse extends Equatable {
  final String id;
  final String? subject;
  final ChatStatus status;
  final String sellerId;
  final String sellerName;
  final String? sellerLogo;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final String? orderId;
  final String? orderNumber;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  const ChatResponse({
    required this.id,
    this.subject,
    required this.status,
    required this.sellerId,
    required this.sellerName,
    this.sellerLogo,
    this.userId,
    this.userName,
    this.userAvatar,
    this.productId,
    this.productTitle,
    this.productImage,
    this.orderId,
    this.orderNumber,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String?,
      status: _parseStatus(json['status'] as String?),
      sellerId: json['seller_id'] as String? ?? '',
      sellerName: json['seller_name'] as String? ?? '',
      sellerLogo: json['seller_logo'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      productId: json['product_id'] as String?,
      productTitle: json['product_title'] as String?,
      productImage: json['product_image'] as String?,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static ChatStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ARCHIVED':
        return ChatStatus.archived;
      case 'RESOLVED':
        return ChatStatus.resolved;
      default:
        return ChatStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'status': status.name.toUpperCase(),
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_logo': sellerLogo,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'product_id': productId,
      'product_title': productTitle,
      'product_image': productImage,
      'order_id': orderId,
      'order_number': orderNumber,
      'last_message_preview': lastMessagePreview,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatResponse copyWith({
    String? id,
    String? subject,
    ChatStatus? status,
    String? sellerId,
    String? sellerName,
    String? sellerLogo,
    String? userId,
    String? userName,
    String? userAvatar,
    String? productId,
    String? productTitle,
    String? productImage,
    String? orderId,
    String? orderNumber,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return ChatResponse(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerLogo: sellerLogo ?? this.sellerLogo,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    subject,
    status,
    sellerId,
    sellerName,
    sellerLogo,
    userId,
    userName,
    userAvatar,
    productId,
    productTitle,
    productImage,
    orderId,
    orderNumber,
    lastMessagePreview,
    lastMessageAt,
    unreadCount,
    createdAt,
  ];
}

/// Chat Message Response Model (snake_case JSON from API)
class ChatMessageResponse extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final SenderType senderType;
  final String content;
  final MessageType messageType;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final int? productPrice;
  final String? color;
  final String? size;
  final int? quantity;
  final bool isRead;
  final DateTime? readAt;
  final List<MessageAttachment> attachments;
  final DateTime createdAt;

  const ChatMessageResponse({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.messageType,
    this.productId,
    this.productTitle,
    this.productImage,
    this.productPrice,
    this.color,
    this.size,
    this.quantity,
    this.isRead = false,
    this.readAt,
    this.attachments = const [],
    required this.createdAt,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderType: _parseSenderType(json['sender_type'] as String?),
      content: json['content'] as String? ?? '',
      messageType: _parseMessageType(json['message_type'] as String?),
      productId: json['product_id'] as String?,
      productTitle: json['product_title'] as String?,
      productImage: json['product_image'] as String?,
      productPrice: json['product_price'] as int?,
      color: json['color'] as String?,
      size: json['size'] as String?,
      quantity: json['quantity'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (a) => MessageAttachment.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static SenderType _parseSenderType(String? type) {
    switch (type?.toUpperCase()) {
      case 'SELLER':
        return SenderType.seller;
      case 'ADMIN':
        return SenderType.admin;
      default:
        return SenderType.user;
    }
  }

  static MessageType _parseMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      case 'PRODUCT':
        return MessageType.product;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType.name.toUpperCase(),
      'content': content,
      'message_type': messageType.name.toUpperCase(),
      'product_id': productId,
      'product_title': productTitle,
      'product_image': productImage,
      'product_price': productPrice,
      'color': color,
      'size': size,
      'quantity': quantity,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    senderName,
    senderType,
    content,
    messageType,
    productId,
    productTitle,
    productImage,
    productPrice,
    color,
    size,
    quantity,
    isRead,
    readAt,
    attachments,
    createdAt,
  ];
}

/// Create Chat Request Model
class CreateChatRequest {
  final String sellerId;
  final String? productId;
  final String? orderId;
  final String? color;
  final String? size;
  final int? quantity;
  final String? subject;
  final String? message;

  const CreateChatRequest({
    required this.sellerId,
    this.productId,
    this.orderId,
    this.color,
    this.size,
    this.quantity,
    this.subject,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      if (productId != null) 'productId': productId,
      if (orderId != null) 'orderId': orderId,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (quantity != null) 'quantity': quantity,
      if (subject != null) 'subject': subject,
      if (message != null) 'message': message,
    };
  }
}

/// Send Message Request Model
class SendMessageRequest {
  final String content;
  final MessageType type;
  final String? productId;
  final String? color;
  final String? size;
  final int? quantity;
  final List<Map<String, dynamic>>? attachments;

  const SendMessageRequest({
    required this.content,
    this.type = MessageType.text,
    this.productId,
    this.color,
    this.size,
    this.quantity,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type.name.toUpperCase(),
      if (productId != null) 'productId': productId,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (quantity != null) 'quantity': quantity,
      if (attachments != null) 'attachments': attachments,
    };
  }
}

/// Backward compatibility wrapper
class ChatModel {
  final ChatResponse chat;

  ChatModel(this.chat);

  String get id => chat.id;
  String get sellerName => chat.sellerName;
  String get sellerAvatar => chat.sellerLogo ?? '';
  String get lastMessage => chat.lastMessagePreview ?? '';
  DateTime get lastMessageTime => chat.lastMessageAt ?? chat.createdAt;
  int get unreadCount => chat.unreadCount;
  String? get productImage => chat.productImage;
  String? get productName => chat.productTitle;
  int? get productPrice => null; // Not in ChatResponse
  int? get productOriginalPrice => null; // Not in ChatResponse

  factory ChatModel.fromChatResponse(ChatResponse chat) => ChatModel(chat);
}
