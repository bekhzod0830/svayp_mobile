/// Visual Search API Service
/// Picks an image locally and posts it to the visual search endpoint.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';

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
  ///
  /// The request runs outside the Dio client, so it manages auth itself:
  /// [apiClient] provides a proactively-refreshed token, and on a 401/403 the
  /// token is force-refreshed and the upload retried once — mirroring the
  /// auto-refresh every other request in the app gets from the Dio interceptor.
  /// Without this, the token captured before the (slow) gallery-pick + crop
  /// step is often expired by request time and the backend rejects it with 401.
  Future<VisualSearchResponse> fetchRecommendations({
    required XFile image,
    required ApiClient apiClient,
    int limit = 20,
    String? category,
  }) async {
    final token = await apiClient.getValidToken();
    var result = await _send(
      image: image,
      token: token,
      limit: limit,
      category: category,
    );

    // Token rejected mid-flight → force one refresh and retry.
    if (result.statusCode == 401 || result.statusCode == 403) {
      final refreshed = await apiClient.refreshAccessToken();
      if (refreshed != null && refreshed != token) {
        result = await _send(
          image: image,
          token: refreshed,
          limit: limit,
          category: category,
        );
      }
    }

    if (result.statusCode == 200) {
      final jsonData = json.decode(result.body) as Map<String, dynamic>;
      return VisualSearchResponse.fromJson(jsonData);
    }
    throw VisualSearchException(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  /// Performs a single multipart POST to the visual search endpoint.
  Future<({int statusCode, String body})> _send({
    required XFile image,
    required String? token,
    required int limit,
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
    return (statusCode: streamed.statusCode, body: body);
  }
}

/// Thrown when the visual search endpoint returns a non-200 response.
/// Carries the HTTP [statusCode] so callers can log/diagnose the real cause
/// (e.g. 401 auth, 413 too large) instead of a generic failure.
class VisualSearchException implements Exception {
  final int statusCode;
  final String body;

  const VisualSearchException({required this.statusCode, required this.body});

  @override
  String toString() => 'VisualSearchException($statusCode): $body';
}
