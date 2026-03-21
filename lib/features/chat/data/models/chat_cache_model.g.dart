// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_cache_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatCacheModelAdapter extends TypeAdapter<ChatCacheModel> {
  @override
  final int typeId = 4;

  @override
  ChatCacheModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatCacheModel(
      chatId: fields[0] as String,
      sellerName: fields[1] as String,
      sellerLogo: fields[2] as String?,
      userName: fields[3] as String?,
      userAvatar: fields[4] as String?,
      productTitle: fields[5] as String?,
      productImage: fields[6] as String?,
      lastMessagePreview: fields[7] as String?,
      lastMessageAt: fields[8] as DateTime?,
      unreadCount: fields[9] as int,
      createdAt: fields[10] as DateTime,
      status: fields[11] as String,
      sellerId: fields[12] as String,
      userId: fields[13] as String?,
      productId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatCacheModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.chatId)
      ..writeByte(1)
      ..write(obj.sellerName)
      ..writeByte(2)
      ..write(obj.sellerLogo)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.userAvatar)
      ..writeByte(5)
      ..write(obj.productTitle)
      ..writeByte(6)
      ..write(obj.productImage)
      ..writeByte(7)
      ..write(obj.lastMessagePreview)
      ..writeByte(8)
      ..write(obj.lastMessageAt)
      ..writeByte(9)
      ..write(obj.unreadCount)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.sellerId)
      ..writeByte(13)
      ..write(obj.userId)
      ..writeByte(14)
      ..write(obj.productId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCacheModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
