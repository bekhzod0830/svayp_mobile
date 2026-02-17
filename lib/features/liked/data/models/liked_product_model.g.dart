// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LikedProductModelAdapter extends TypeAdapter<LikedProductModel> {
  @override
  final int typeId = 1;

  @override
  LikedProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LikedProductModel(
      productId: fields[0] as String,
      brand: fields[1] as String,
      title: fields[2] as String,
      price: fields[3] as int,
      imageUrl: fields[4] as String,
      category: fields[5] as String,
      rating: fields[6] as double,
      likedAt: fields[7] as DateTime?,
      isNew: fields[8] as bool,
      discountPercentage: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LikedProductModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.brand)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.likedAt)
      ..writeByte(8)
      ..write(obj.isNew)
      ..writeByte(9)
      ..write(obj.discountPercentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LikedProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
