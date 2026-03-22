import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Order Status Enum - matches API values
enum OrderStatus {
  waiting,        // WAITING          – created, awaiting seller confirmation
  confirmed,      // CONFIRMED        – confirmed by seller
  readyToShip,    // READY_TO_SHIP    – ready to ship (delivery)
  readyForPickup, // READY_FOR_PICKUP – ready for pickup (self-pickup)
  shipped,        // SHIPPED          – in delivery
  delivered,      // DELIVERED        – delivered by courier
  completed,      // COMPLETED        – customer received the goods
  cancelled,      // CANCELLED        – cancelled
  returned,       // RETURNED         – goods returned
  voided,         // VOIDED           – voided (terminal)
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
  final Map<String, String>? productTitleLocalized;
  final Map<String, String>? productDescriptionLocalized;

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
    this.productTitleLocalized,
    this.productDescriptionLocalized,
  });

  /// Get localized product title, falling back to productTitle
  String localizedTitle(String languageCode) {
    if (productTitleLocalized == null) return productTitle;
    return productTitleLocalized![languageCode] ??
        productTitleLocalized!['en'] ??
        productTitle;
  }

  /// Get localized product description
  String localizedDescription(String languageCode) {
    if (productDescriptionLocalized == null) return '';
    return productDescriptionLocalized![languageCode] ??
        productDescriptionLocalized!['en'] ??
        '';
  }

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
      productTitleLocalized:
          (json['productTitleLocalized'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ),
      productDescriptionLocalized:
          (json['productDescriptionLocalized'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ),
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
  // Fields from admin/seller endpoint
  final String? clientName;
  final String? clientPhone;

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
    this.clientName,
    this.clientPhone,
  });

  /// Factory constructor from JSON.
  /// Handles two API formats:
  ///   1. Regular user format – has nested `items[]`, `subtotal`, `shippingCost`, `paymentStatus`
  ///   2. Admin/seller flat format – has `clientName`, `pricePerUnit`, `finalAmount`, `deliveryFee`
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Detect admin flat format by presence of flat product fields
    final isAdminFormat =
        json['clientName'] != null || json['pricePerUnit'] != null;

    List<OrderItemModel> items;
    double subtotal;
    double shippingCost;
    double totalAmount;

    if (isAdminFormat) {
      // Build a single synthetic OrderItemModel from the flat fields
      final qty = (json['quantity'] as num?)?.toInt() ?? 1;
      final unitPrice = (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0;
      final itemSubtotal =
          (json['totalAmount'] as num?)?.toDouble() ?? unitPrice * qty;

      items = [
        OrderItemModel(
          id: json['id'] as String? ?? '',
          productId: json['productId'] as String? ?? '',
          productTitle: json['productTitle'] as String? ?? '',
          productImage: json['productImage'] as String?,
          selectedSize: json['size'] as String?,
          selectedColor: json['color'] as String?,
          unitPrice: unitPrice,
          quantity: qty,
          subtotal: itemSubtotal,
          productTitleLocalized:
              (json['productTitleLocalized'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v.toString()),
              ),
          productDescriptionLocalized:
              (json['productDescriptionLocalized'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())),
        ),
      ];

      subtotal = itemSubtotal;
      shippingCost = (json['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      // `finalAmount` is the true total; fall back to `totalAmount` if absent
      totalAmount =
          (json['finalAmount'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0;
    } else {
      // Regular format
      items =
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => OrderItemModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [];
      subtotal = (json['subtotal'] as num?)?.toDouble() ?? 0.0;
      shippingCost = (json['shippingCost'] as num?)?.toDouble() ?? 0.0;
      totalAmount = (json['totalAmount'] as num?)?.toDouble() ?? 0.0;
    }

    return OrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      deliveryMethod: json['deliveryMethod'] as String? ?? 'DELIVERY',
      shippingFullName: json['shippingFullName'] as String?,
      shippingPhone: json['shippingPhone'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      shippingCity: json['shippingCity'] as String?,
      subtotal: subtotal,
      shippingCost: shippingCost,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: totalAmount,
      currency: json['currency'] as String? ?? 'UZS',
      status: json['status'] as String? ?? 'WAITING',
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      customerNotes: json['customerNotes'] as String?,
      items: items,
      statusHistory: isAdminFormat
          ? []
          : (json['statusHistory'] as List<dynamic>?)
                    ?.map(
                      (s) => StatusHistoryModel.fromJson(
                        s as Map<String, dynamic>,
                      ),
                    )
                    .toList() ??
                [],
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.parse(json['shippedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
    );
  }

  /// Get order status enum
  OrderStatus get orderStatus {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return OrderStatus.waiting;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'READY_TO_SHIP':
        return OrderStatus.readyToShip;
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'SHIPPED':
        return OrderStatus.shipped;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'RETURNED':
        return OrderStatus.returned;
      case 'VOIDED':
        return OrderStatus.voided;
      default:
        return OrderStatus.waiting;
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
      case OrderStatus.waiting:
        return const Color(0xFFFF9800); // Orange
      case OrderStatus.confirmed:
        return const Color(0xFF2196F3); // Blue
      case OrderStatus.readyToShip:
        return const Color(0xFF009688); // Teal
      case OrderStatus.readyForPickup:
        return const Color(0xFF00BCD4); // Cyan
      case OrderStatus.shipped:
        return const Color(0xFF3F51B5); // Indigo
      case OrderStatus.delivered:
        return const Color(0xFF8BC34A); // Light Green
      case OrderStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case OrderStatus.cancelled:
        return const Color(0xFFF44336); // Red
      case OrderStatus.returned:
        return const Color(0xFF9E9E9E); // Grey
      case OrderStatus.voided:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  /// Get status display text
  String getLocalizedStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (orderStatus) {
      case OrderStatus.waiting:
        return l10n.waiting;
      case OrderStatus.confirmed:
        return l10n.confirmed;
      case OrderStatus.readyToShip:
        return l10n.readyToShip;
      case OrderStatus.readyForPickup:
        return l10n.readyForPickup;
      case OrderStatus.shipped:
        return l10n.shipped;
      case OrderStatus.delivered:
        return l10n.delivered;
      case OrderStatus.completed:
        return l10n.completed;
      case OrderStatus.cancelled:
        return l10n.cancelled;
      case OrderStatus.returned:
        return l10n.returned;
      case OrderStatus.voided:
        return l10n.voided;
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
