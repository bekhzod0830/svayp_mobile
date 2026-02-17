import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/features/orders/data/models/order_model.dart';

/// Order Service - Manages orders with Hive persistence
class OrderService {
  static const String _boxName = 'order_box';
  Box<OrderModel>? _orderBox;

  /// Initialize the order box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _orderBox = await Hive.openBox<OrderModel>(_boxName);
    } else {
      _orderBox = Hive.box<OrderModel>(_boxName);
    }
  }

  /// Get all orders (sorted by date, newest first)
  List<OrderModel> getOrders() {
    final orders = _orderBox?.values.toList() ?? [];
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return orders;
  }

  /// Get order by ID
  OrderModel? getOrderById(String id) {
    final orders = getOrders();
    try {
      return orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add new order
  Future<void> addOrder(OrderModel order) async {
    await _orderBox?.put(order.id, order);
  }

  /// Update existing order
  Future<void> updateOrder(OrderModel order) async {
    await _orderBox?.put(order.id, order);
  }

  /// Delete order
  Future<void> deleteOrder(String id) async {
    await _orderBox?.delete(id);
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    final orders = getOrders();
    return orders.where((order) => order.status == status).toList();
  }

  /// Get pending orders
  List<OrderModel> getPendingOrders() {
    return getOrdersByStatus('pending');
  }

  /// Get delivered orders
  List<OrderModel> getDeliveredOrders() {
    return getOrdersByStatus('delivered');
  }

  /// Get order count
  int getOrderCount() {
    return _orderBox?.length ?? 0;
  }

  /// Check if order exists
  bool orderExists(String id) {
    return _orderBox?.containsKey(id) ?? false;
  }

  /// Clear all orders
  Future<void> clearOrders() async {
    await _orderBox?.clear();
  }

  /// Get stream of order changes
  Stream<List<OrderModel>> watchOrders() {
    return _orderBox?.watch().map((_) => getOrders()) ?? Stream.empty();
  }

  /// Update order status
  Future<void> updateOrderStatus(String id, String status) async {
    final order = getOrderById(id);
    if (order == null) return;

    order.status = status;

    // Update delivered date if status is delivered
    if (status.toLowerCase() == 'delivered' && order.deliveredDate == null) {
      order.deliveredDate = DateTime.now();
    }

    await updateOrder(order);
  }

  /// Add tracking number to order
  Future<void> addTrackingNumber(String id, String trackingNumber) async {
    final order = getOrderById(id);
    if (order == null) return;

    order.trackingNumber = trackingNumber;
    await updateOrder(order);
  }

  /// Close the box
  Future<void> close() async {
    await _orderBox?.close();
  }
}
