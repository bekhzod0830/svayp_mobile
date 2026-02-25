import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/auth/data/models/auth_models.dart';
import 'package:swipe/core/models/product.dart';

/// Partner Service
/// Handles partner-specific API calls including user verification,
/// product fetching, and cashback operations
class PartnerService {
  final ApiClient _apiClient;

  PartnerService(this._apiClient);

  /// Verify if a user exists by user ID
  ///
  /// GET /api/v1/admin/users/{userId}
  /// Returns user information if exists, throws exception if not found
  Future<UserResponse> verifyUser(String userId) async {
    try {
      final response = await _apiClient.get('/admin/users/$userId');

      // The response should be wrapped in a "data" envelope
      final data = response.data;
      if (data == null) {
        throw Exception('No data received from server');
      }

      if (data is Map<String, dynamic>) {
        // Check if response has a 'data' key
        final userData = data.containsKey('data') ? data['data'] : data;

        if (userData is Map<String, dynamic>) {
          return UserResponse.fromJson(userData);
        }
      }

      throw Exception('Invalid response format: $data');
    } catch (e) {
      rethrow;
    }
  }

  /// Get all products for the authenticated seller
  ///
  /// GET /api/v1/admin/products
  /// Returns list of products available for this seller
  Future<ProductListResponse> getSellerProducts({
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        '/admin/products',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw Exception('No data received from server');
      }

      if (data is Map<String, dynamic>) {
        // ProductListResponse.fromJson expects the full response with 'data' and 'pagination'
        return ProductListResponse.fromJson(data);
      }

      throw Exception('Invalid response format: $data');
    } catch (e) {
      rethrow;
    }
  }

  /// Record a cashback transaction via QR sale
  ///
  /// POST /api/v1/qr-sale
  /// Creates a new QR sale record for a customer purchase
  Future<Map<String, dynamic>> recordCashback({
    required String customerId,
    required List<CashbackProductItem> products,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'userId': customerId,
        'items': products
            .map(
              (p) => {
                'productId': p.productId,
                'quantity': p.quantity,
                'size': p.size ?? '',
                'color': p.color ?? '',
                'customPrice': p.finalPrice.toInt(),
              },
            )
            .toList(),
      };

      final response = await _apiClient.post('/qr-sale', data: requestBody);

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      return {'success': true, 'data': response.data};
    } catch (e) {
      rethrow;
    }
  }
}

/// Cashback Product Item
/// Represents a product in a cashback transaction
class CashbackProductItem {
  final String productId;
  final String productName;
  final String? size;
  final String? color;
  final int quantity;
  final double originalPrice;
  final double discount;
  final String discountType; // "percent" or "flat"
  final double finalPrice;

  CashbackProductItem({
    required this.productId,
    required this.productName,
    this.size,
    this.color,
    required this.quantity,
    required this.originalPrice,
    required this.discount,
    required this.discountType,
    required this.finalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      'quantity': quantity,
      'original_price': originalPrice,
      'discount': discount,
      'discount_type': discountType,
      'final_price': finalPrice,
    };
  }
}
