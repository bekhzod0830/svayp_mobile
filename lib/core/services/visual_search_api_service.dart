/// Visual Search API Service
/// Picks an image locally and posts it to the visual search endpoint.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Response models
// ─────────────────────────────────────────────────────────────────────────────

/// A single item returned by the visual search endpoint
class VisualSearchResult {
  final Product product;
  final double similarity;
  final String? matchedColorCode;
  final String? matchedImageUrl;

  const VisualSearchResult({
    required this.product,
    required this.similarity,
    this.matchedColorCode,
    this.matchedImageUrl,
  });

  factory VisualSearchResult.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>? ?? {};
    return VisualSearchResult(
      product: Product.fromJson(productJson),
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      matchedColorCode: json['matchedColorCode'] as String?,
      matchedImageUrl: json['matchedImageUrl'] as String?,
    );
  }

  /// Similarity as a rounded percentage string, e.g. "87%"
  String get similarityLabel => '${(similarity * 100).round()}%';
}

/// Top-level response wrapper from the visual search endpoint
class VisualSearchResponse {
  final List<VisualSearchResult> results;
  final String? message;

  const VisualSearchResponse({required this.results, this.message});

  factory VisualSearchResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return VisualSearchResponse(
      results: dataList
          .map((e) => VisualSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class VisualSearchApiService {
  VisualSearchApiService();

  String get _baseUrl => ApiConfig.baseUrl;

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

  /// Send [image] to the visual search endpoint and return matching products.
  ///
  /// Uses POST /api/v1/products/search/visual?limit=<limit> with multipart/form-data.
  /// [token] optional JWT for authorised requests.
  Future<VisualSearchResponse> fetchRecommendations({
    required XFile image,
    String? token,
    int limit = 20,
    String? category,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (category != null) params['category'] = category;
    final uri = Uri.parse(
      '$_baseUrl/products/search/visual',
    ).replace(queryParameters: params);

    final request = http.MultipartRequest('POST', uri);

    request.headers['accept'] = '*/*';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Field name must match the backend: 'image'
    // Detect MIME type from extension (jpeg/png/webp/etc.)
    final ext = image.path.split('.').last.toLowerCase();
    final mimeSubtype = ext == 'jpg' ? 'jpeg' : ext;

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final jsonData = json.decode(body) as Map<String, dynamic>;
      return VisualSearchResponse.fromJson(jsonData);
    } else {
      throw Exception('Visual search failed: ${streamed.statusCode} $body');
    }
  }
}
