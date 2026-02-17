import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/features/payment/data/models/payment_method_model.dart';

/// Payment Method Service - Manages payment methods with Hive persistence
class PaymentMethodService {
  static const String _boxName = 'payment_method_box';
  Box<PaymentMethodModel>? _paymentBox;

  /// Initialize the payment method box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _paymentBox = await Hive.openBox<PaymentMethodModel>(_boxName);
    } else {
      _paymentBox = Hive.box<PaymentMethodModel>(_boxName);
    }

    // Add default Cash on Delivery if no methods exist
    if (getPaymentMethods().isEmpty) {
      await addPaymentMethod(PaymentMethodModel.cashOnDelivery());
    }
  }

  /// Get all payment methods
  List<PaymentMethodModel> getPaymentMethods() {
    return _paymentBox?.values.toList() ?? [];
  }

  /// Get default payment method
  PaymentMethodModel? getDefaultPaymentMethod() {
    final methods = getPaymentMethods();
    try {
      return methods.firstWhere((method) => method.isDefault);
    } catch (e) {
      // No default method found, return first or COD
      return methods.isNotEmpty ? methods.first : null;
    }
  }

  /// Get payment method by ID
  PaymentMethodModel? getPaymentMethodById(String id) {
    final methods = getPaymentMethods();
    try {
      return methods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add new payment method
  Future<void> addPaymentMethod(PaymentMethodModel paymentMethod) async {
    // If this is the first method or is marked as default, make it default
    if (getPaymentMethods().isEmpty || paymentMethod.isDefault) {
      await _clearDefaultFlags();
      paymentMethod.isDefault = true;
    }

    await _paymentBox?.put(paymentMethod.id, paymentMethod);
  }

  /// Update existing payment method
  Future<void> updatePaymentMethod(PaymentMethodModel paymentMethod) async {
    paymentMethod.updatedAt = DateTime.now();

    // If setting as default, clear other default flags
    if (paymentMethod.isDefault) {
      await _clearDefaultFlags();
    }

    await _paymentBox?.put(paymentMethod.id, paymentMethod);
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String id) async {
    final method = getPaymentMethodById(id);
    if (method == null) return;

    // Prevent deleting the last payment method
    if (getPaymentMethods().length == 1) {
      throw Exception('Cannot delete the last payment method');
    }

    final wasDefault = method.isDefault;
    await _paymentBox?.delete(id);

    // If we deleted the default method, set another as default
    if (wasDefault) {
      final remainingMethods = getPaymentMethods();
      if (remainingMethods.isNotEmpty) {
        remainingMethods.first.isDefault = true;
        await _paymentBox?.put(
          remainingMethods.first.id,
          remainingMethods.first,
        );
      }
    }
  }

  /// Set payment method as default
  Future<void> setDefaultPaymentMethod(String id) async {
    final method = getPaymentMethodById(id);
    if (method == null) return;

    await _clearDefaultFlags();
    method.isDefault = true;
    await _paymentBox?.put(id, method);
  }

  /// Clear all default flags
  Future<void> _clearDefaultFlags() async {
    final methods = getPaymentMethods();
    for (final method in methods) {
      if (method.isDefault) {
        method.isDefault = false;
        await _paymentBox?.put(method.id, method);
      }
    }
  }

  /// Get payment method count
  int getPaymentMethodCount() {
    return _paymentBox?.length ?? 0;
  }

  /// Check if payment method exists
  bool paymentMethodExists(String id) {
    return _paymentBox?.containsKey(id) ?? false;
  }

  /// Clear all payment methods (and re-add COD)
  Future<void> clearPaymentMethods() async {
    await _paymentBox?.clear();
    // Always keep Cash on Delivery as an option
    await addPaymentMethod(PaymentMethodModel.cashOnDelivery());
  }

  /// Get stream of payment method changes
  Stream<List<PaymentMethodModel>> watchPaymentMethods() {
    return _paymentBox?.watch().map((_) => getPaymentMethods()) ??
        Stream.empty();
  }

  /// Close the box
  Future<void> close() async {
    await _paymentBox?.close();
  }
}
