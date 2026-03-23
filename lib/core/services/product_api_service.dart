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

      final response = await http.get(uri, headers: headers);

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

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductListResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to search products: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final response = await http.get(uri, headers: headers);

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

      final response = await http.post(uri, headers: headers);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to like product: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final response = await http.post(uri, headers: headers);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to dislike product: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // The favorites endpoint returns nested data: {"data": {"data": [...], "total": ...}}
        // Extract the inner data object
        final innerData = jsonData['data'] as Map<String, dynamic>;

        return ProductListResponse.fromJson(innerData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for favorites');
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet - return empty list
        return ProductListResponse(products: [], total: 0);
      } else {
        throw Exception(
          'Failed to load favorites: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final response = await http.get(uri, headers: headers);

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

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to delete cart item');
      } else {
        throw Exception(
          'Failed to delete cart item: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final response = await http.patch(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to update cart item');
      } else {
        throw Exception(
          'Failed to update cart item: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to clear cart');
      } else {
        throw Exception(
          'Failed to clear cart: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
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

      final bodyMap = {
        'productId': productId,
        'selectedSize': selectedSize.toUpperCase(),
        if (selectedColor != null) 'selectedColor': selectedColor,
        'quantity': quantity,
      };
      final body = json.encode(bodyMap);

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to add to cart');
      } else {
        throw Exception(
          'Failed to add to cart: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get quiz feed - lightweight image-only product cards for onboarding quiz
  ///
  /// Endpoint: GET /api/v1/feed/quiz
  ///
  /// Parameters:
  /// - [limit]: Number of quiz items to return (default 10)
  /// - [token]: Optional authentication token
  Future<List<Map<String, dynamic>>> getQuizFeed({
    int limit = 10,
    String? token,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/feed/quiz',
      ).replace(queryParameters: {'limit': limit.toString()});

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        // Response is a direct array of QuizProductResponse
        if (jsonData is List) {
          return jsonData.whereType<Map<String, dynamic>>().toList();
        }
        // Or wrapped in data
        if (jsonData is Map<String, dynamic>) {
          final data = jsonData['data'];
          if (data is List) {
            return data.whereType<Map<String, dynamic>>().toList();
          }
        }
        return [];
      } else {
        throw Exception(
          'Failed to load quiz feed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Log a user interaction event
  ///
  /// Endpoint: POST /api/v1/events
  ///
  /// Parameters:
  /// - [productId]: UUID of the product being interacted with
  /// - [eventType]: Type of event ('SWIPE', 'VIEW', 'CART_ADD', etc.)
  /// - [swipeAction]: Swipe direction – 'LIKE' or 'DISLIKE' (only for SWIPE events)
  /// - [viewDurationMs]: Optional view duration in milliseconds
  /// - [context]: Optional context map
  /// - [metadata]: Optional extra metadata map
  /// - [token]: Optional authentication token
  Future<void> logEvent({
    required String productId,
    required String eventType,
    String? swipeAction,
    int? viewDurationMs,
    Map<String, dynamic>? context,
    Map<String, dynamic>? metadata,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/events');

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = json.encode({
        'productId': productId,
        'eventType': eventType,
        if (swipeAction != null) 'swipeAction': swipeAction,
        if (viewDurationMs != null) 'viewDurationMs': viewDurationMs,
        if (context != null) 'context': context,
        if (metadata != null) 'metadata': metadata,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Silently fail – event logging should never disrupt the user
      }
    } catch (_) {
      // Never propagate event-logging errors
    }
  }

  /// Get personalized swipe feed
  ///
  /// Endpoint: GET /api/v1/feed
  ///
  /// Parameters:
  /// - [limit]: Number of items to return (default 20)
  /// - [cursor]: Pagination cursor from previous response
  /// - [category]: Optional category filter
  /// - [token]: Required authentication token
  Future<ProductListResponse> getFeed({
    int limit = 20,
    String? cursor,
    String? category,
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};
      if (cursor != null) queryParams['cursor'] = cursor;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse(
        '$baseUrl/feed',
      ).replace(queryParameters: queryParams);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // CursorPagedResponseProductResponse – extract the items list
        List<dynamic>? itemsList;

        if (jsonData is Map<String, dynamic>) {
          final data = jsonData['data'];
          if (data is Map<String, dynamic>) {
            itemsList =
                data['items'] as List<dynamic>? ??
                data['data'] as List<dynamic>? ??
                data['products'] as List<dynamic>?;
          } else if (data is List) {
            itemsList = data;
          } else {
            // Try top-level keys directly
            itemsList =
                jsonData['items'] as List<dynamic>? ??
                jsonData['data'] as List<dynamic>?;
          }
        } else if (jsonData is List) {
          itemsList = jsonData;
        }

        final products = <Product>[];
        if (itemsList != null) {
          for (final item in itemsList) {
            try {
              products.add(Product.fromJson(item as Map<String, dynamic>));
            } catch (_) {
              // Skip products that fail to parse
            }
          }
        }

        return ProductListResponse(products: products, total: products.length);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for feed');
      } else {
        throw Exception(
          'Failed to load feed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get seller basic info (logo, locations, contact)
  ///
  /// Endpoint: GET /api/v1/sellers/{sellerId}
  Future<SellerInfo> getSeller({
    required String sellerId,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/sellers/$sellerId');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sellerData = jsonData['data'] ?? jsonData;
        return SellerInfo.fromJson(sellerData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load seller: ${response.statusCode}');
      }
    } catch (e) {
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

  /// Get paginated list of all active sellers
  ///
  /// Endpoint: GET /api/v1/sellers?skip=0&limit=50&isActive=true
  Future<List<SellerInfo>> getSellers({
    int skip = 0,
    int limit = 50,
    bool isActive = true,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
        'isActive': isActive.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/sellers',
      ).replace(queryParameters: queryParams);
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        // Handle multiple possible response shapes
        final data = jsonData['data'] ?? jsonData;
        final List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items =
              (data['items'] ??
                      data['sellers'] ??
                      data['content'] ??
                      data['data'] ??
                      [])
                  as List<dynamic>;
        } else {
          items = [];
        }
        return items
            .map((e) => SellerInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load sellers: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// A single physical location of a seller (store/outlet)
class SellerLocation {
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final bool isPrimary;

  const SellerLocation({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.isPrimary = false,
  });

  factory SellerLocation.fromJson(Map<String, dynamic> json) {
    return SellerLocation(
      name: json['name'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'phone_number': phoneNumber,
    'is_primary': isPrimary,
  };
}

/// Basic seller info returned by GET /api/v1/sellers/{sellerId}
class SellerInfo {
  final String id;
  final String name;
  final String? logoImg;
  final String? description;
  final int? productCount;
  final List<SellerLocation> locations;
  final String? websiteUrl;
  final String? primaryAddress;
  final String? phoneNumber;

  const SellerInfo({
    required this.id,
    required this.name,
    this.logoImg,
    this.description,
    this.productCount,
    this.locations = const [],
    this.websiteUrl,
    this.primaryAddress,
    this.phoneNumber,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    final locationsList =
        (json['locations'] as List<dynamic>?)
            ?.map((l) => SellerLocation.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];
    return SellerInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoImg: json['logo_img'] as String?,
      description: json['description'] as String?,
      productCount: (json['product_count'] as num?)?.toInt(),
      locations: locationsList,
      websiteUrl: json['website_url'] as String?,
      primaryAddress: json['primary_address'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_img': logoImg,
    'description': description,
    'product_count': productCount,
    'locations': locations.map((l) => l.toJson()).toList(),
    'website_url': websiteUrl,
    'primary_address': primaryAddress,
    'phone_number': phoneNumber,
  };
}
