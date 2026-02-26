/// Visual Search API Service
/// Picks an image and fetches product recommendations from the backend.

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
  /// [image] the image file to search with.
  /// [token] optional auth token for personalised results.
  /// [limit] number of products to return.
  Future<ProductListResponse> fetchRecommendations({
    required XFile image,
    String? token,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/products/search/visual');

    // Create multipart request
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add image file
    final bytes = await image.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: image.name),
    );

    // Add limit parameter
    request.fields['limit'] = limit.toString();

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

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
