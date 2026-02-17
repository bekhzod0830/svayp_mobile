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
  /// - [skip]: Number of items to skip (for pagination)
  /// - [limit]: Number of items to return (default 20)
  /// - [category]: Filter by category
  /// - [gender]: Filter by gender target
  /// - [hijabAppropriate]: Filter hijab-appropriate items
  /// - [minPrice]: Minimum price filter
  /// - [maxPrice]: Maximum price filter
  /// - [search]: Search query
  /// - [token]: Optional authentication token
  Future<ProductListResponse> getProducts({
    int skip = 0,
    int limit = 20,
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
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (category != null) queryParams['category'] = category;
      if (gender != null) queryParams['gender'] = gender;
      if (hijabAppropriate != null)
        queryParams['hijab_appropriate'] = hijabAppropriate.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse(
        '$baseUrl/products',
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
        return Product.fromJson(jsonData);
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
  /// - [skip]: Number of items to skip (for pagination)
  /// - [limit]: Number of items to return
  /// - [token]: Optional authentication token
  Future<ProductListResponse> searchProducts({
    required String query,
    int skip = 0,
    int limit = 20,
    String? token,
  }) async {
    return getProducts(skip: skip, limit: limit, search: query, token: token);
  }

  /// Get products by category
  Future<ProductListResponse> getProductsByCategory({
    required String category,
    int skip = 0,
    int limit = 20,
    String? token,
  }) async {
    return getProducts(
      skip: skip,
      limit: limit,
      category: category,
      token: token,
    );
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({String? token}) async {
    final response = await getProducts(limit: 10, token: token);
    return response.products.where((p) => p.isFeatured == true).toList();
  }

  /// Get new arrivals
  Future<List<Product>> getNewArrivals({String? token}) async {
    final response = await getProducts(limit: 10, token: token);
    return response.products.where((p) => p.isNew == true).toList();
  }

  /// Get recommended products based on user profile
  ///
  /// Parameters:
  /// - [token]: Required authentication token
  Future<ProductListResponse> getRecommendedProducts({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/recommended');

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
}
