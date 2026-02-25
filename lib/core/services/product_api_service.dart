/// Product API Service
/// Handles all product-related API calls

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config/api_config.dart';

class ProductApiService {
  // Base URL from centralized config
  // Change environment in api_config.dart based on where you're testing
  String get baseUrl => ApiConfig.baseUrl;

  /// Get list of products with optional filters
  ///
  /// Parameters:
  /// - [page]: Page number (for pagination, starts from 0)
  /// - [size]: Number of items to return per page (default 20)
  /// - [category]: Filter by category
  /// - [gender]: Filter by gender target
  /// - [hijabAppropriate]: Filter hijab-appropriate items
  /// - [minPrice]: Minimum price filter
  /// - [maxPrice]: Maximum price filter
  /// - [search]: Search query
  /// - [token]: Optional authentication token
  Future<ProductListResponse> getProducts({
    int page = 0,
    int size = 20,
    String? category,
    String? gender,
    bool? hijabAppropriate,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null) queryParams['category'] = category;
      if (gender != null) queryParams['gender'] = gender;
      if (hijabAppropriate != null)
        queryParams['hijab_appropriate'] = hijabAppropriate.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse(
        '$baseUrl/products/all',
      ).replace(queryParameters: queryParams);

      // Build headers
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductListResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load products: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching products: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  ///
  /// Parameters:
  /// - [productId]: Product ID
  /// - [token]: Optional authentication token
  Future<Product> getProductById(String productId, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$productId');

      // Build headers
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('📡 GET $uri');

      final response = await http.get(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Check if data is nested in "data" field
        final productData = jsonData['data'] ?? jsonData;

        return Product.fromJson(productData);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception(
          'Failed to load product: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching product: $e');
      rethrow;
    }
  }

  /// Search products
  ///
  /// Parameters:
  /// - [query]: Search query
  /// - [page]: Page number (for pagination, starts from 0)
  /// - [size]: Number of items to return per page
  /// - [token]: Optional authentication token
  Future<ProductListResponse> searchProducts({
    required String query,
    int page = 0,
    int size = 20,
    String? token,
  }) async {
    return getProducts(page: page, size: size, search: query, token: token);
  }

  /// Search products using the /products/search endpoint
  ///
  /// Parameters:
  /// - [query]: Search query string
  /// - [page]: Page number (for pagination, starts from 0)
  /// - [size]: Number of items to return per page (default 20)
  /// - [token]: Optional authentication token
  Future<ProductListResponse> searchProductsApi({
    required String query,
    int page = 0,
    int size = 20,
    String? token,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'q': query,
        'page': page.toString(),
        'size': size.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/products/search',
      ).replace(queryParameters: queryParams);

      // Build headers
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('📡 GET $uri');

      final response = await http.get(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductListResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to search products: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<ProductListResponse> getProductsByCategory({
    required String category,
    int page = 0,
    int size = 20,
    String? token,
  }) async {
    return getProducts(
      page: page,
      size: size,
      category: category,
      token: token,
    );
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({String? token}) async {
    final response = await getProducts(size: 10, token: token);
    return response.products.where((p) => p.isFeatured == true).toList();
  }

  /// Get new arrivals
  Future<List<Product>> getNewArrivals({String? token}) async {
    final response = await getProducts(size: 10, token: token);
    return response.products.where((p) => p.isNew == true).toList();
  }

  /// Get recommended products based on user profile
  ///
  /// Parameters:
  /// - [token]: Required authentication token
  /// - [limit]: Number of recommendations to return (default 20)
  Future<ProductListResponse> getRecommendedProducts({
    required String token,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/recommendations?limit=$limit');

      // Build headers with required authentication
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 GET $uri');

      final response = await http.get(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductListResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for recommendations');
      } else {
        throw Exception(
          'Failed to load recommendations: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching recommendations: $e');
      rethrow;
    }
  }

  /// Like a product
  ///
  /// Parameters:
  /// - [productId]: Product ID to like
  /// - [token]: Required authentication token
  Future<void> likeProduct({
    required String productId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$productId/like');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 POST $uri');

      final response = await http.post(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to like product: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error liking product: $e');
      rethrow;
    }
  }

  /// Dislike a product
  ///
  /// Parameters:
  /// - [productId]: Product ID to dislike
  /// - [token]: Required authentication token
  Future<void> dislikeProduct({
    required String productId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$productId/dislike');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 POST $uri');

      final response = await http.post(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to dislike product: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error disliking product: $e');
      rethrow;
    }
  }

  /// Get favorite products
  ///
  /// Parameters:
  /// - [token]: Required authentication token
  Future<ProductListResponse> getFavoriteProducts({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/favorites');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 GET $uri');

      final response = await http.get(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📡 Decoded JSON type: ${jsonData.runtimeType}');
        print(
          '📡 JSON keys: ${jsonData is Map ? jsonData.keys.toList() : "Not a map"}',
        );

        // The favorites endpoint returns nested data: {"data": {"data": [...], "total": ...}}
        // Extract the inner data object
        final innerData = jsonData['data'] as Map<String, dynamic>;
        print('📡 Inner data keys: ${innerData.keys.toList()}');

        return ProductListResponse.fromJson(innerData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for favorites');
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet - return empty list
        print('⚠️ Favorites endpoint not found (404) - returning empty list');
        return ProductListResponse(products: [], total: 0);
      } else {
        throw Exception(
          'Failed to load favorites: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching favorites: $e');
      rethrow;
    }
  }

  /// Get shopping cart
  ///
  /// Parameters:
  /// - [token]: Required authentication token
  Future<Map<String, dynamic>> getCart({required String token}) async {
    try {
      final uri = Uri.parse('$baseUrl/cart');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 GET $uri');

      final response = await http.get(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to get cart');
      } else {
        throw Exception(
          'Failed to get cart: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching cart: $e');
      rethrow;
    }
  }

  /// Delete item from cart
  ///
  /// Parameters:
  /// - [itemId]: Cart item ID to delete
  /// - [token]: Required authentication token
  Future<void> deleteCartItem({
    required String itemId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/$itemId');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 DELETE $uri');

      final response = await http.delete(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Successfully deleted cart item');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to delete cart item');
      } else {
        throw Exception(
          'Failed to delete cart item: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error deleting cart item: $e');
      rethrow;
    }
  }

  /// Update cart item quantity
  ///
  /// Parameters:
  /// - [itemId]: Cart item ID to update
  /// - [quantity]: New quantity
  /// - [token]: Required authentication token
  Future<void> updateCartItem({
    required String itemId,
    required int quantity,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/$itemId');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({'quantity': quantity});

      print('📡 PATCH $uri');
      print('📦 Update data: $body');

      final response = await http.patch(uri, headers: headers, body: body);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Successfully updated cart item');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to update cart item');
      } else {
        throw Exception(
          'Failed to update cart item: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error updating cart item: $e');
      rethrow;
    }
  }

  /// Clear entire cart
  ///
  /// Parameters:
  /// - [token]: Required authentication token
  Future<void> clearCart({required String token}) async {
    try {
      final uri = Uri.parse('$baseUrl/cart');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 DELETE $uri');

      final response = await http.delete(uri, headers: headers);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Successfully cleared cart');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to clear cart');
      } else {
        throw Exception(
          'Failed to clear cart: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }

  /// Add product to cart
  ///
  /// Parameters:
  /// - [productId]: Product ID to add
  /// - [selectedSize]: Selected size for the product
  /// - [selectedColor]: Selected color for the product
  /// - [quantity]: Quantity to add (default 1)
  /// - [token]: Required authentication token
  Future<void> addToCart({
    required String productId,
    required String selectedSize,
    String? selectedColor,
    int quantity = 1,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'productId': productId,
        'selectedSize': selectedSize,
        if (selectedColor != null) 'selectedColor': selectedColor,
        'quantity': quantity,
      });

      print('📡 POST $uri');
      print('📦 Cart data: $body');

      final response = await http.post(uri, headers: headers, body: body);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Successfully added to cart');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to add to cart');
      } else {
        throw Exception(
          'Failed to add to cart: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  /// Get seller details with all products
  ///
  /// Endpoint: /api/v1/sellers/{sellerId}/detail
  ///
  /// Parameters:
  /// - [brandId]: Seller name or ID (kept as brandId for backward compatibility)
  /// - [skip]: Number of items to skip (for pagination)
  /// - [limit]: Number of items to return (default 20)
  /// - [sort]: Sort order (e.g., 'newest', 'price_asc', 'price_desc')
  /// - [token]: Optional authentication token
  Future<ProductListResponse> getBrandDetail({
    required String brandId,
    int skip = 0,
    int limit = 20,
    String sort = 'newest',
    String? token,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      final uri = Uri.parse(
        '$baseUrl/sellers/$brandId/detail',
      ).replace(queryParameters: queryParams);

      // Build headers
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductListResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Seller not found');
      } else {
        throw Exception(
          'Failed to load seller details: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
