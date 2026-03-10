/// Visual Search API Service
/// Picks an image locally and fetches product recommendations from the backend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../config/api_config.dart';

class VisualSearchApiService {
  VisualSearchApiService();

  String get baseUrl => ApiConfig.baseUrl;

  /// Pick image from gallery or camera.
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final picker = ImagePicker();
      return await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch product recommendations from the backend using visual search.
  ///
  /// Uses GET /api/v1/products/search/visual?limit=<limit>
  ///
  /// [token] optional auth token for personalised results.
  /// [limit] number of products to return (default 20).
  Future<ProductListResponse> fetchRecommendations({
    String? token,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/products/search/visual',
    ).replace(queryParameters: {'limit': limit.toString()});

    // Build headers
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Send GET request
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ProductListResponse.fromJson(jsonData);
    } else {
      throw Exception(
        'Visual search failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
