import 'package:swipe/features/orders/data/models/order_model.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';

/// Order Service - Manages orders via API
class OrderService {
  final ApiClient? _apiClient;

  /// Constructor - requires ApiClient for API calls
  OrderService([this._apiClient]);

  /// Fetch all orders from API with pagination
  Future<List<OrderModel>> fetchOrders({int page = 0, int size = 10}) async {
    if (_apiClient == null) {
      throw Exception('ApiClient not initialized. Cannot fetch orders.');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.orders}?page=$page&size=$size',
      );

      // Extract orders from nested response structure
      // API returns: {"data": {"data": [...], "pagination": {...}}, "message": "..."}
      final data = response.data['data'];

      // Handle nested data structure
      List<dynamic> ordersData;
      if (data is Map) {
        // Nested structure: {"data": {"data": [...], "pagination": {...}}}
        ordersData = data['data'] ?? [];
      } else if (data is List) {
        // Flat structure: {"data": [...]}
        ordersData = data;
      } else {
        print('⚠️ Unexpected data structure in response');
        ordersData = [];
      }

      final orders = <OrderModel>[];
      for (final orderJson in ordersData) {
        try {
          orders.add(OrderModel.fromJson(orderJson as Map<String, dynamic>));
        } catch (e) {
          print('⚠️ Failed to parse order: $e');
          print('   Order JSON: $orderJson');
        }
      }

      // Sort by date, newest first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Parsed ${orders.length} orders');
      return orders;
    } catch (e) {
      print('❌ Error fetching orders: $e');
      rethrow;
    }
  }

  /// Get order by ID from API
  Future<OrderModel?> fetchOrderById(String id) async {
    if (_apiClient == null) {
      throw Exception('ApiClient not initialized. Cannot fetch order.');
    }

    try {
      print('📦 Fetching order $id from API');

      final endpoint = ApiConfig.orderDetail.replaceAll('{id}', id);
      final response = await _apiClient.get(endpoint);

      final orderData = response.data['data'];
      return OrderModel.fromJson(orderData as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching order $id: $e');
      return null;
    }
  }

  /// Place order via API
  ///
  /// Creates an order on the server from the user's cart
  /// The API reads cart items from the server-side cart, not from the request
  /// Returns the created order data on success
  Future<Map<String, dynamic>> placeOrderApi({
    String? addressId,
    required String deliveryMethod,
    required String paymentMethod,
  }) async {
    if (_apiClient == null) {
      throw Exception('ApiClient not initialized. Cannot place order via API.');
    }

    try {
      // Convert delivery method to API format
      // API expects: PICKUP or DELIVERY (not pickup, standard, express, sameday)
      final apiDeliveryMethod = deliveryMethod.toLowerCase() == 'pickup'
          ? 'PICKUP'
          : 'DELIVERY';

      // Convert payment method to API format (e.g., "CASH", "CARD")
      // If it starts with 'cod_' or is 'cod', use 'CASH'
      final apiPaymentMethod =
          paymentMethod.toLowerCase().contains('cod') ||
              paymentMethod.toLowerCase() == 'cash'
          ? 'CASH'
          : paymentMethod.toUpperCase();

      // Prepare request body - API creates order from server-side cart
      final requestBody = {
        'deliveryMethod': apiDeliveryMethod,
        'paymentMethod': apiPaymentMethod,
      };

      // Add addressId only if delivery (not pickup)
      if (apiDeliveryMethod == 'DELIVERY' && addressId != null) {
        requestBody['addressId'] = addressId;
      }

      print('📦 Placing order via API: ${ApiConfig.orders}');
      print('📤 Request body: $requestBody');

      final response = await _apiClient.post(
        ApiConfig.orders,
        data: requestBody,
      );

      print('✅ Order placed successfully: ${response.data}');

      // Extract order data from response
      // API typically returns: {data: {...order data}, message: "..."}
      final orderData = response.data['data'] ?? response.data;
      return orderData as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error placing order: $e');
      rethrow;
    }
  }
}
