import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Order Status Enum - matches API values
enum OrderStatus {
  created,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

/// Payment Status Enum - matches API values
enum PaymentStatus { pending, paid, failed, refunded }

/// Order Item Model - represents items in an order
class OrderItemModel {
  final String id;
  final String productId;
  final String productTitle;
  final String? productImage;
  final String? productSku;
  final String? selectedSize;
  final String? selectedColor;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productImage,
    this.productSku,
    this.selectedSize,
    this.selectedColor,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productTitle: json['productTitle'] ?? '',
      productImage: json['productImage'],
      productSku: json['productSku'],
      selectedSize: json['selectedSize'],
      selectedColor: json['selectedColor'],
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'productSku': productSku,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

/// Status History Model
class StatusHistoryModel {
  final String status;
  final String? note;
  final DateTime createdAt;

  StatusHistoryModel({
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryModel(
      status: json['status'] ?? '',
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Order Model - matches API response structure
class OrderModel {
  final String id;
  final String orderNumber;
  final String deliveryMethod; // DELIVERY or PICKUP
  final String? shippingFullName;
  final String? shippingPhone;
  final String? shippingAddress;
  final String? shippingCity;
  final double subtotal;
  final double shippingCost;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String
  status; // CREATED, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
  final String paymentMethod; // CASH, CARD, etc.
  final String paymentStatus; // PENDING, PAID, FAILED, REFUNDED
  final String? customerNotes;
  final List<OrderItemModel> items;
  final List<StatusHistoryModel> statusHistory;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.deliveryMethod,
    this.shippingFullName,
    this.shippingPhone,
    this.shippingAddress,
    this.shippingCity,
    required this.subtotal,
    required this.shippingCost,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.customerNotes,
    required this.items,
    required this.statusHistory,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
  });

  /// Factory constructor from JSON - matches API response
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      deliveryMethod: json['deliveryMethod'] ?? 'DELIVERY',
      shippingFullName: json['shippingFullName'],
      shippingPhone: json['shippingPhone'],
      shippingAddress: json['shippingAddress'],
      shippingCity: json['shippingCity'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shippingCost: (json['shippingCost'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'UZS',
      status: json['status'] ?? 'CREATED',
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      customerNotes: json['customerNotes'],
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => OrderItemModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statusHistory:
          (json['statusHistory'] as List<dynamic>?)
              ?.map(
                (status) =>
                    StatusHistoryModel.fromJson(status as Map<String, dynamic>),
              )
              .toList() ??
          [],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.parse(json['shippedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Get order status enum
  OrderStatus get orderStatus {
    switch (status.toUpperCase()) {
      case 'CREATED':
        return OrderStatus.created;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PROCESSING':
        return OrderStatus.processing;
      case 'SHIPPED':
        return OrderStatus.shipped;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.created;
    }
  }

  /// Get payment status enum
  PaymentStatus get paymentStatusEnum {
    switch (paymentStatus.toUpperCase()) {
      case 'PAID':
        return PaymentStatus.paid;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      case 'PENDING':
      default:
        return PaymentStatus.pending;
    }
  }

  /// Get formatted total
  String get formattedTotal {
    return '${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
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
    return '${createdAt.day} ${months[createdAt.month - 1]}, ${createdAt.year}';
  }

  /// Get item count
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get status color
  Color get statusColor {
    switch (orderStatus) {
      case OrderStatus.created:
      case OrderStatus.confirmed:
        return const Color(0xFFFFA500); // Orange
      case OrderStatus.processing:
      case OrderStatus.shipped:
        return const Color(0xFF2196F3); // Blue
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
      case OrderStatus.created:
        return l10n.pending;
      case OrderStatus.confirmed:
        return l10n.confirmed;
      case OrderStatus.processing:
        return l10n.processing;
      case OrderStatus.shipped:
        return l10n.shipped;
      case OrderStatus.delivered:
        return l10n.delivered;
      case OrderStatus.cancelled:
        return l10n.cancelled;
    }
  }

  /// Get delivery method display text
  String getLocalizedDeliveryMethod(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (deliveryMethod.toUpperCase()) {
      case 'PICKUP':
        return l10n.pickup;
      case 'DELIVERY':
      default:
        return l10n.delivery;
    }
  }

  /// Get payment method display text
  String getLocalizedPaymentMethod(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (paymentMethod.toUpperCase()) {
      case 'CASH':
        return l10n.cashOnDelivery;
      case 'CARD':
        return l10n.cardPayment;
      default:
        return paymentMethod;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'deliveryMethod': deliveryMethod,
      'shippingFullName': shippingFullName,
      'shippingPhone': shippingPhone,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity,
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'customerNotes': customerNotes,
      'items': items.map((item) => item.toJson()).toList(),
      'statusHistory': statusHistory.map((status) => status.toJson()).toList(),
      'paidAt': paidAt?.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
