import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/features/closet/data/models/closet_item_model.dart';

/// Manages the user's local closet using Hive Box(String) JSON strings.
/// No Hive adapter / build_runner required.
///
/// Backend upload is a TODO — all data is local for now.
class ClosetService {
  static const String _boxName = 'closet_items_box';
  Box<String>? _box;

  Future<void> _ensureOpen() async {
    if (_box != null && _box!.isOpen) return;
    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box<String>(_boxName)
        : await Hive.openBox<String>(_boxName);
  }

  /// Returns all items, newest first. Pass [category] to filter.
  Future<List<ClosetItemModel>> listItems({ClosetCategory? category}) async {
    await _ensureOpen();
    final all = _box!.values
        .map((s) {
          try {
            return ClosetItemModel.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<ClosetItemModel>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return category == null
        ? all
        : all.where((i) => i.category == category).toList();
  }

  /// Saves a new item locally and returns it.
  /// TODO: upload to backend when `/closet/items` endpoint is ready.
  Future<ClosetItemModel> addItem({
    required File imageFile,
    required ClosetCategory category,
    String? brand,
    String? notes,
  }) async {
    await _ensureOpen();
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final item = ClosetItemModel(
      id: id,
      category: category,
      imagePath: imageFile.path,
      isLocalFile: true,
      brand: (brand?.trim().isEmpty ?? true) ? null : brand!.trim(),
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      createdAt: DateTime.now(),
    );
    await _box!.put(id, item.toJsonString());
    return item;
  }

  /// Removes an item by ID.
  /// TODO: call DELETE /closet/items/{id} when backend is ready.
  Future<void> deleteItem(String id) async {
    await _ensureOpen();
    await _box!.delete(id);
  }

  /// Updates an existing item (e.g. change category). Replaces by ID.
  Future<ClosetItemModel> updateItem(ClosetItemModel updated) async {
    await _ensureOpen();
    await _box!.put(updated.id, updated.toJsonString());
    return updated;
  }

  /// Wipes all closet data. Call on logout.
  Future<void> clearAll() async {
    await _ensureOpen();
    await _box!.clear();
  }
}
