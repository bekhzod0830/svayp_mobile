// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CartItemModelAdapter extends TypeAdapter<CartItemModel> {
  @override
  final int typeId = 0;

  @override
  CartItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItemModel(
      productId: fields[0] as String,
      brand: fields[1] as String,
      title: fields[2] as String,
      price: fields[3] as int,
      imageUrl: fields[4] as String,
      quantity: fields[5] as int,
      selectedSize: fields[6] as String,
      selectedColor: fields[7] as String?,
      category: fields[8] as String,
      currency:
          (fields[10] as String?) ??
          'UZS', // Default to UZS for backward compatibility
      titleLocalized: (fields[11] as Map<dynamic, dynamic>?)
          ?.cast<String, String>(),
      descriptionLocalized: (fields[12] as Map<dynamic, dynamic>?)
          ?.cast<String, String>(),
      addedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CartItemModel obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.selectedSize)
      ..writeByte(7)
      ..write(obj.selectedColor)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.addedAt)
      ..writeByte(10)
      ..write(obj.currency)
      ..writeByte(11)
      ..write(obj.titleLocalized)
      ..writeByte(12)
      ..write(obj.descriptionLocalized);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
