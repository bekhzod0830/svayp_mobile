import 'dart:convert';
import 'package:flutter/material.dart';

/// Clothing categories for the closet feature.
enum ClosetCategory {
  // Upper body
  tops,
  dresses,
  jackets,
  blouses,
  jumpsuits,
  tshirts,
  // Lower body
  skirts,
  jeans,
  pants,
  shorts,
  // Shoes
  shoes,
  // Accessories
  accessories,
  bags,
  shawl,
  jewelry,
  underwear;

  String get key => name;

  static ClosetCategory fromKey(String key) => ClosetCategory.values.firstWhere(
        (c) => c.name == key,
        orElse: () => ClosetCategory.tops,
      );

  IconData get icon => switch (this) {
        ClosetCategory.tops => Icons.checkroom_outlined,
        ClosetCategory.dresses => Icons.woman_outlined,
        ClosetCategory.jackets => Icons.layers_outlined,
        ClosetCategory.blouses => Icons.dry_cleaning_outlined,
        ClosetCategory.jumpsuits => Icons.accessibility_outlined,
        ClosetCategory.tshirts => Icons.dry_cleaning_outlined,
        ClosetCategory.skirts => Icons.woman_outlined,
        ClosetCategory.jeans => Icons.straighten_outlined,
        ClosetCategory.pants => Icons.straighten_outlined,
        ClosetCategory.shorts => Icons.straighten_outlined,
        ClosetCategory.shoes => Icons.directions_walk_outlined,
        ClosetCategory.accessories => Icons.watch_outlined,
        ClosetCategory.bags => Icons.shopping_bag_outlined,
        ClosetCategory.shawl => Icons.texture,
        ClosetCategory.jewelry => Icons.diamond,
        ClosetCategory.underwear => Icons.checkroom,
      };
}

/// A single item stored in the user's local closet.
/// Persisted as a JSON string in a Hive string box.
class ClosetItemModel {
  final String id;
  final ClosetCategory category;

  /// Local file path (when [isLocalFile] is true) or a CDN URL.
  final String imagePath;
  final bool isLocalFile;
  final String? brand;
  final String? notes;
  final DateTime createdAt;

  const ClosetItemModel({
    required this.id,
    required this.category,
    required this.imagePath,
    this.isLocalFile = true,
    this.brand,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.key,
        'imagePath': imagePath,
        'isLocalFile': isLocalFile,
        if (brand != null) 'brand': brand,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClosetItemModel.fromJson(Map<String, dynamic> json) =>
      ClosetItemModel(
        id: json['id'] as String,
        category: ClosetCategory.fromKey(json['category'] as String? ?? 'tops'),
        imagePath: json['imagePath'] as String,
        isLocalFile: json['isLocalFile'] as bool? ?? true,
        brand: json['brand'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory ClosetItemModel.fromJsonString(String s) =>
      ClosetItemModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  ClosetItemModel copyWith({
    ClosetCategory? category,
    String? imagePath,
    bool? isLocalFile,
    String? brand,
    String? notes,
  }) =>
      ClosetItemModel(
        id: id,
        category: category ?? this.category,
        imagePath: imagePath ?? this.imagePath,
        isLocalFile: isLocalFile ?? this.isLocalFile,
        brand: brand ?? this.brand,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
