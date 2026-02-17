import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/features/address/data/models/address_model.dart';

/// Address Service - Manages delivery addresses with Hive persistence
class AddressService {
  static const String _boxName = 'address_box';
  Box<AddressModel>? _addressBox;

  /// Initialize the address box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _addressBox = await Hive.openBox<AddressModel>(_boxName);
    } else {
      _addressBox = Hive.box<AddressModel>(_boxName);
    }
  }

  /// Get all addresses
  List<AddressModel> getAddresses() {
    return _addressBox?.values.toList() ?? [];
  }

  /// Get default address
  AddressModel? getDefaultAddress() {
    final addresses = getAddresses();
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      // No default address found
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  /// Get address by ID
  AddressModel? getAddressById(String id) {
    final addresses = getAddresses();
    try {
      return addresses.firstWhere((address) => address.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add new address
  Future<void> addAddress(AddressModel address) async {
    // If this is the first address or is marked as default, make it default
    if (getAddresses().isEmpty || address.isDefault) {
      await _clearDefaultFlags();
      address.isDefault = true;
    }

    await _addressBox?.put(address.id, address);
  }

  /// Update existing address
  Future<void> updateAddress(AddressModel address) async {
    address.updatedAt = DateTime.now();

    // If setting as default, clear other default flags
    if (address.isDefault) {
      await _clearDefaultFlags();
    }

    await _addressBox?.put(address.id, address);
  }

  /// Delete address
  Future<void> deleteAddress(String id) async {
    final address = getAddressById(id);
    if (address == null) return;

    final wasDefault = address.isDefault;
    await _addressBox?.delete(id);

    // If we deleted the default address, set another as default
    if (wasDefault) {
      final remainingAddresses = getAddresses();
      if (remainingAddresses.isNotEmpty) {
        remainingAddresses.first.isDefault = true;
        await _addressBox?.put(
          remainingAddresses.first.id,
          remainingAddresses.first,
        );
      }
    }
  }

  /// Set address as default
  Future<void> setDefaultAddress(String id) async {
    final address = getAddressById(id);
    if (address == null) return;

    await _clearDefaultFlags();
    address.isDefault = true;
    await _addressBox?.put(id, address);
  }

  /// Clear all default flags
  Future<void> _clearDefaultFlags() async {
    final addresses = getAddresses();
    for (final address in addresses) {
      if (address.isDefault) {
        address.isDefault = false;
        await _addressBox?.put(address.id, address);
      }
    }
  }

  /// Get address count
  int getAddressCount() {
    return _addressBox?.length ?? 0;
  }

  /// Check if address exists
  bool addressExists(String id) {
    return _addressBox?.containsKey(id) ?? false;
  }

  /// Clear all addresses
  Future<void> clearAddresses() async {
    await _addressBox?.clear();
  }

  /// Get stream of address changes
  Stream<List<AddressModel>> watchAddresses() {
    return _addressBox?.watch().map((_) => getAddresses()) ?? Stream.empty();
  }

  /// Close the box
  Future<void> close() async {
    await _addressBox?.close();
  }
}
