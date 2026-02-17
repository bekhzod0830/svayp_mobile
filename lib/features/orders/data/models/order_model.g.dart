// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 4;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      id: fields[0] as String,
      items: (fields[1] as List).cast<CartItemModel>(),
      orderDate: fields[2] as DateTime,
      status: fields[3] as String,
      subtotal: fields[4] as double,
      deliveryFee: fields[5] as double,
      total: fields[6] as double,
      deliveryAddressId: fields[7] as String,
      deliveryAddressName: fields[8] as String,
      deliveryAddressPhone: fields[9] as String,
      deliveryAddressFormatted: fields[10] as String,
      paymentMethodId: fields[11] as String,
      paymentMethodName: fields[12] as String,
      deliveryMethod: fields[13] as String,
      trackingNumber: fields[14] as String?,
      estimatedDeliveryDate: fields[15] as DateTime?,
      deliveredDate: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.orderDate)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.subtotal)
      ..writeByte(5)
      ..write(obj.deliveryFee)
      ..writeByte(6)
      ..write(obj.total)
      ..writeByte(7)
      ..write(obj.deliveryAddressId)
      ..writeByte(8)
      ..write(obj.deliveryAddressName)
      ..writeByte(9)
      ..write(obj.deliveryAddressPhone)
      ..writeByte(10)
      ..write(obj.deliveryAddressFormatted)
      ..writeByte(11)
      ..write(obj.paymentMethodId)
      ..writeByte(12)
      ..write(obj.paymentMethodName)
      ..writeByte(13)
      ..write(obj.deliveryMethod)
      ..writeByte(14)
      ..write(obj.trackingNumber)
      ..writeByte(15)
      ..write(obj.estimatedDeliveryDate)
      ..writeByte(16)
      ..write(obj.deliveredDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
