/// Visual Search API Service
/// Handles visual search API calls and image uploads

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/visual_search.dart';
import '../models/product.dart';
import '../config/api_config.dart';
import '../constants/product_enums.dart';

class VisualSearchApiService {
  final bool useMockData;

  VisualSearchApiService({this.useMockData = true});

  String get baseUrl => ApiConfig.baseUrl;

  /// Upload image and perform visual search
  ///
  /// Parameters:
  /// - [imageFile]: Image file from camera or gallery
  /// - [minSimilarity]: Minimum similarity threshold (0.0 - 1.0)
  /// - [maxResults]: Maximum number of results
  /// - [token]: Optional authentication token for personalized results
  Future<VisualSearchResponse> visualSearch({
    required XFile imageFile,
    double minSimilarity = 0.5,
    int maxResults = 20,
    String? token,
  }) async {
    // Use mock data if enabled (for development before backend deployment)
    if (useMockData) {
      return _getMockVisualSearchResponse();
    }

    try {
      // Step 1: Upload the image first
      final imageUrl = await _uploadImage(imageFile, token);

      // Step 2: Perform visual search with uploaded image URL
      final uri = Uri.parse('$baseUrl/products/visual-search');

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final requestBody = json.encode({
        'image_url': imageUrl,
        'min_similarity': minSimilarity,
        'max_results': maxResults,
        'apply_user_preferences': token != null,
      });

      final response = await http.post(
        uri,
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VisualSearchResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['detail'] ?? 'Visual search failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image to server
  ///
  /// Returns the URL of the uploaded image
  Future<String> _uploadImage(XFile imageFile, String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/uploads/product');

      var request = http.MultipartRequest('POST', uri);

      // Add authorization if available
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image file
      final file = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: imageFile.name,
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final imageUrl = jsonData['url'] as String;
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85, // Good quality for AI analysis
      );

      if (image != null) {
      }

      return image;
    } catch (e) {
      rethrow;
    }
  }

  /// Mock visual search response for development/testing
  /// Returns sample data using local images from assets
  Future<VisualSearchResponse> _getMockVisualSearchResponse() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final now = DateTime.now();

    return VisualSearchResponse(
      analysis: ImageAnalysisResult(
        clothingItem: 'Blazer',
        category: 'Jackets',
        subcategory: 'Casual Blazers',
        colors: ['Olive Green', 'Khaki', 'Beige'],
        patterns: ['Solid'],
        styleCategory: 'Smart Casual',
        fitType: 'Regular',
        coverageLevel: 'Standard Coverage',
        sleeveLength: 'Long Sleeve',
        length: 'Hip Length',
        material: 'Linen Blend',
        occasion: 'Casual',
        styleTags: ['Modern', 'Versatile', 'Comfortable'],
        isHijabAppropriate: true,
        confidence: 0.89,
        rawDescription:
            'A stylish casual blazer in olive/khaki tones with a relaxed fit. Perfect for smart-casual occasions with its comfortable linen blend material.',
      ),
      matches: [
        // Perfect match - moved to first position
        VisualSearchMatch(
          product: Product(
            id: 'mock-6',
            brand: 'ClassicWear',
            title: 'Premium Designer Blazer',
            description: 'High-end blazer with exceptional tailoring',
            category: CategoryEnum.jacket,
            subcategory: [SubcategoryEnum.blazer],
            price: 16000000,
            currency: 'USD',
            images: [
              'lib/img/visual_search/Screenshot 2025-11-18 at 13.05.17.png',
            ],
            inStock: true,
            hijabAppropriate: true,
            coverageLevel: CoverageLevelEnum.standard,
            sleeveLength: SleeveLengthEnum.long,
            fitType: FitTypeEnum.tailored,
            createdAt: now,
          ),
          similarityScore: 1.0,
          matchDetails: MatchDetails(
            categoryMatch: 1.0,
            colorMatch: 1.0,
            patternMatch: 1.0,
            styleMatch: 1.0,
            coverageMatch: 1.0,
            fitMatch: 1.0,
            sleeveMatch: 1.0,
            lengthMatch: 1.0,
            occasionMatch: 1.0,
            materialMatch: 1.0,
          ),
        ),
        VisualSearchMatch(
          product: Product(
            id: 'mock-1',
            brand: 'ModestStyle',
            title: 'Olive Green Blazer Jacket',
            description: 'Elegant casual blazer with modern cut',
            category: CategoryEnum.jacket,
            subcategory: [SubcategoryEnum.blazer],
            price: 12900000,
            currency: 'USD',
            images: [
              'lib/img/visual_search/yag-yesili-blazer-ceket-053d82.png',
            ],
            inStock: true,
            hijabAppropriate: true,
            coverageLevel: CoverageLevelEnum.standard,
            sleeveLength: SleeveLengthEnum.long,
            fitType: FitTypeEnum.regular,
            createdAt: now,
          ),
          similarityScore: 0.96,
          matchDetails: MatchDetails(
            categoryMatch: 1.0,
            colorMatch: 0.98,
            patternMatch: 1.0,
            styleMatch: 0.95,
            coverageMatch: 0.92,
            fitMatch: 0.94,
            sleeveMatch: 1.0,
            lengthMatch: 0.96,
            occasionMatch: 0.90,
            materialMatch: 0.88,
          ),
        ),
        VisualSearchMatch(
          product: Product(
            id: 'mock-2',
            brand: 'UrbanModest',
            title: 'Khaki Linen Blazer',
            description:
                'Comfortable side-tie linen jacket for versatile styling',
            category: CategoryEnum.jacket,
            subcategory: [SubcategoryEnum.blazer],
            price: 11400000,
            currency: 'USD',
            images: [
              'lib/img/visual_search/yandan-baglama-keten-ceket-haki-152569.png',
            ],
            inStock: true,
            hijabAppropriate: true,
            coverageLevel: CoverageLevelEnum.standard,
            sleeveLength: SleeveLengthEnum.long,
            fitType: FitTypeEnum.regular,
            createdAt: now,
          ),
          similarityScore: 0.93,
          matchDetails: MatchDetails(
            categoryMatch: 1.0,
            colorMatch: 0.95,
            patternMatch: 1.0,
            styleMatch: 0.92,
            coverageMatch: 0.90,
            fitMatch: 0.91,
            sleeveMatch: 1.0,
            lengthMatch: 0.94,
            occasionMatch: 0.88,
            materialMatch: 0.96,
          ),
        ),
        VisualSearchMatch(
          product: Product(
            id: 'mock-3',
            brand: 'ChicModest',
            title: 'Classic Beige Blazer',
            description: 'Timeless blazer design with elegant fit',
            category: CategoryEnum.jacket,
            subcategory: [SubcategoryEnum.blazer],
            price: 10900000,
            currency: 'USD',
            images: ['lib/img/visual_search/blazer.png'],
            inStock: true,
            hijabAppropriate: true,
            coverageLevel: CoverageLevelEnum.standard,
            sleeveLength: SleeveLengthEnum.long,
            fitType: FitTypeEnum.tailored,
            createdAt: now,
          ),
          similarityScore: 0.88,
          matchDetails: MatchDetails(
            categoryMatch: 1.0,
            colorMatch: 0.87,
            patternMatch: 1.0,
            styleMatch: 0.90,
            coverageMatch: 0.88,
            fitMatch: 0.85,
            sleeveMatch: 1.0,
            lengthMatch: 0.92,
            occasionMatch: 0.86,
            materialMatch: 0.82,
          ),
        ),
        VisualSearchMatch(
          product: Product(
            id: 'mock-4',
            brand: 'ModernWear',
            title: 'Contemporary Blazer Style',
            description: 'Modern approach to classic blazer design',
            category: CategoryEnum.jacket,
            subcategory: [SubcategoryEnum.blazer],
            price: 13500000,
            currency: 'USD',
            images: ['lib/img/visual_search/image_1080.png'],
            inStock: true,
            hijabAppropriate: true,
            coverageLevel: CoverageLevelEnum.standard,
            sleeveLength: SleeveLengthEnum.long,
            fitType: FitTypeEnum.regular,
            createdAt: now,
          ),
          similarityScore: 0.85,
          matchDetails: MatchDetails(
            categoryMatch: 1.0,
            colorMatch: 0.84,
            patternMatch: 0.98,
            styleMatch: 0.88,
            coverageMatch: 0.86,
            fitMatch: 0.83,
            sleeveMatch: 1.0,
            lengthMatch: 0.90,
            occasionMatch: 0.82,
            materialMatch: 0.80,
          ),
        ),
        VisualSearchMatch(
          product: Product(
            id: 'mock-5',
            brand: 'ElegantModest',
            title: 'Zoom Detail Blazer',
            description: 'Sophisticated blazer with premium finish',
            category: CategoryEnum.jacket,
            subcategory: [SubcategoryEnum.blazer],
            price: 15000000,
            currency: 'USD',
            images: ['lib/img/visual_search/1_org_zoom.png'],
            inStock: true,
            hijabAppropriate: true,
            coverageLevel: CoverageLevelEnum.standard,
            sleeveLength: SleeveLengthEnum.long,
            fitType: FitTypeEnum.tailored,
            createdAt: now,
          ),
          similarityScore: 0.82,
          matchDetails: MatchDetails(
            categoryMatch: 1.0,
            colorMatch: 0.80,
            patternMatch: 0.96,
            styleMatch: 0.85,
            coverageMatch: 0.84,
            fitMatch: 0.82,
            sleeveMatch: 1.0,
            lengthMatch: 0.88,
            occasionMatch: 0.78,
            materialMatch: 0.76,
          ),
        ),
      ],
      totalMatches: 6,
      searchTimeMs: 2300,
    );
  }
}
