import 'package:hive/hive.dart';

part 'payment_method_model.g.dart';

/// Payment Method Types
enum PaymentType {
  cashOnDelivery,
  uzcard,
  humo,
  click,
  payme,
  visa,
  mastercard,
}

/// Payment Method Model for Hive Persistence
@HiveType(typeId: 3)
class PaymentMethodModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type; // Store as string for Hive compatibility

  @HiveField(2)
  late String displayName;

  @HiveField(3)
  late bool isDefault;

  @HiveField(4)
  String? cardNumber; // Last 4 digits or full for local storage

  @HiveField(5)
  String? cardHolderName;

  @HiveField(6)
  String? expiryDate; // MM/YY format

  @HiveField(7)
  String? phoneNumber; // For Click/Payme

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.type,
    required this.displayName,
    this.isDefault = false,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  /// Get payment type enum
  PaymentType get paymentType {
    switch (type.toLowerCase()) {
      case 'cashondelivery':
        return PaymentType.cashOnDelivery;
      case 'uzcard':
        return PaymentType.uzcard;
      case 'humo':
        return PaymentType.humo;
      case 'click':
        return PaymentType.click;
      case 'payme':
        return PaymentType.payme;
      case 'visa':
        return PaymentType.visa;
      case 'mastercard':
        return PaymentType.mastercard;
      default:
        return PaymentType.cashOnDelivery;
    }
  }

  /// Get masked card number (e.g., **** **** **** 1234)
  String get maskedCardNumber {
    if (cardNumber == null || cardNumber!.isEmpty) return '';
    if (cardNumber!.length <= 4) return cardNumber!;
    return '**** **** **** ${cardNumber!.substring(cardNumber!.length - 4)}';
  }

  /// Get display subtitle
  String get displaySubtitle {
    switch (paymentType) {
      case PaymentType.cashOnDelivery:
        return 'Pay when you receive your order';
      case PaymentType.click:
      case PaymentType.payme:
        return phoneNumber ?? '';
      case PaymentType.uzcard:
      case PaymentType.humo:
      case PaymentType.visa:
      case PaymentType.mastercard:
        return maskedCardNumber;
    }
  }

  /// Get icon name for payment method
  String get iconName {
    switch (paymentType) {
      case PaymentType.cashOnDelivery:
        return 'cash';
      case PaymentType.uzcard:
        return 'uzcard';
      case PaymentType.humo:
        return 'humo';
      case PaymentType.click:
        return 'click';
      case PaymentType.payme:
        return 'payme';
      case PaymentType.visa:
        return 'visa';
      case PaymentType.mastercard:
        return 'mastercard';
    }
  }

  /// Copy with method
  PaymentMethodModel copyWith({
    String? id,
    String? type,
    String? displayName,
    bool? isDefault,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      isDefault: isDefault ?? this.isDefault,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'displayName': displayName,
      'isDefault': isDefault,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      type: json['type'] as String,
      displayName: json['displayName'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      cardNumber: json['cardNumber'] as String?,
      cardHolderName: json['cardHolderName'] as String?,
      expiryDate: json['expiryDate'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Helper to create Cash on Delivery method
  factory PaymentMethodModel.cashOnDelivery() {
    return PaymentMethodModel(
      id: 'cod_${DateTime.now().millisecondsSinceEpoch}',
      type: 'cashOnDelivery',
      displayName: 'Cash on Delivery',
      isDefault: true,
    );
  }
}
