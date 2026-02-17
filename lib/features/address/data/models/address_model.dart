import 'package:hive/hive.dart';

part 'address_model.g.dart';

/// Address Model for Hive Persistence
/// Represents a delivery address for orders
@HiveType(typeId: 2)
class AddressModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String fullName;

  @HiveField(2)
  late String phoneNumber;

  @HiveField(3)
  late String street;

  @HiveField(4)
  late String city;

  @HiveField(5)
  late String region;

  @HiveField(6)
  late String postalCode;

  @HiveField(7)
  late bool isDefault;

  @HiveField(8)
  String? apartmentNumber;

  @HiveField(9)
  String? landmark;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.region,
    required this.postalCode,
    this.isDefault = false,
    this.apartmentNumber,
    this.landmark,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  /// Get formatted address (single line)
  String get formattedAddress {
    final parts = <String>[
      street,
      if (apartmentNumber != null && apartmentNumber!.isNotEmpty)
        'Apt $apartmentNumber',
      city,
      region,
      postalCode,
    ];
    return parts.join(', ');
  }

  /// Get formatted address (multi-line)
  String get formattedAddressMultiLine {
    final lines = <String>[
      street,
      if (apartmentNumber != null && apartmentNumber!.isNotEmpty)
        'Apartment: $apartmentNumber',
      '$city, $region $postalCode',
      if (landmark != null && landmark!.isNotEmpty) 'Landmark: $landmark',
    ];
    return lines.join('\n');
  }

  /// Copy with method
  AddressModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? street,
    String? city,
    String? region,
    String? postalCode,
    bool? isDefault,
    String? apartmentNumber,
    String? landmark,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      city: city ?? this.city,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      landmark: landmark ?? this.landmark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'street': street,
      'city': city,
      'region': region,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'apartmentNumber': apartmentNumber,
      'landmark': landmark,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      region: json['region'] as String,
      postalCode: json['postalCode'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      apartmentNumber: json['apartmentNumber'] as String?,
      landmark: json['landmark'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
