import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';

part 'order_model.g.dart';

/// Order Status Enum
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

/// Order Model for Hive Persistence
@HiveType(typeId: 4)
class OrderModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late List<CartItemModel> items;

  @HiveField(2)
  late DateTime orderDate;

  @HiveField(3)
  late String status; // Store as string for Hive compatibility

  @HiveField(4)
  late double subtotal;

  @HiveField(5)
  late double deliveryFee;

  @HiveField(6)
  late double total;

  @HiveField(7)
  late String deliveryAddressId;

  @HiveField(8)
  late String deliveryAddressName;

  @HiveField(9)
  late String deliveryAddressPhone;

  @HiveField(10)
  late String deliveryAddressFormatted;

  @HiveField(11)
  late String paymentMethodId;

  @HiveField(12)
  late String paymentMethodName;

  @HiveField(13)
  late String deliveryMethod; // standard, express, sameday

  @HiveField(14)
  String? trackingNumber;

  @HiveField(15)
  DateTime? estimatedDeliveryDate;

  @HiveField(16)
  DateTime? deliveredDate;

  OrderModel({
    required this.id,
    required this.items,
    required this.orderDate,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddressId,
    required this.deliveryAddressName,
    required this.deliveryAddressPhone,
    required this.deliveryAddressFormatted,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.deliveryMethod,
    this.trackingNumber,
    this.estimatedDeliveryDate,
    this.deliveredDate,
  });

  /// Get order status enum
  OrderStatus get orderStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'outfordelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// Get formatted total
  String get formattedTotal {
    return '${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS';
  }

  /// Get formatted order date
  String get formattedOrderDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${orderDate.day} ${months[orderDate.month - 1]}, ${orderDate.year}';
  }

  /// Get item count
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get status color
  Color get statusColor {
    switch (orderStatus) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return const Color(0xFFFFA500); // Orange
      case OrderStatus.processing:
      case OrderStatus.shipped:
        return const Color(0xFF2196F3); // Blue
      case OrderStatus.outForDelivery:
        return const Color(0xFF9C27B0); // Purple
      case OrderStatus.delivered:
        return const Color(0xFF4CAF50); // Green
      case OrderStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }

  /// Get status display text
  String getLocalizedStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (orderStatus) {
      case OrderStatus.pending:
        return l10n.pending;
      case OrderStatus.confirmed:
        return l10n.confirmed;
      case OrderStatus.processing:
        return l10n.processing;
      case OrderStatus.shipped:
        return l10n.shipped;
      case OrderStatus.outForDelivery:
        return l10n.outForDelivery;
      case OrderStatus.delivered:
        return l10n.delivered;
      case OrderStatus.cancelled:
        return l10n.cancelled;
    }
  }

  /// Copy with method
  OrderModel copyWith({
    String? id,
    List<CartItemModel>? items,
    DateTime? orderDate,
    String? status,
    double? subtotal,
    double? deliveryFee,
    double? total,
    String? deliveryAddressId,
    String? deliveryAddressName,
    String? deliveryAddressPhone,
    String? deliveryAddressFormatted,
    String? paymentMethodId,
    String? paymentMethodName,
    String? deliveryMethod,
    String? trackingNumber,
    DateTime? estimatedDeliveryDate,
    DateTime? deliveredDate,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      deliveryAddressName: deliveryAddressName ?? this.deliveryAddressName,
      deliveryAddressPhone: deliveryAddressPhone ?? this.deliveryAddressPhone,
      deliveryAddressFormatted:
          deliveryAddressFormatted ?? this.deliveryAddressFormatted,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
    );
  }

  /// Convert to JSON (simplified - items stored as Hive objects)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemCount': items.length,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'deliveryAddressId': deliveryAddressId,
      'deliveryAddressName': deliveryAddressName,
      'deliveryAddressPhone': deliveryAddressPhone,
      'deliveryAddressFormatted': deliveryAddressFormatted,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'deliveryMethod': deliveryMethod,
      'trackingNumber': trackingNumber,
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
    };
  }
}
