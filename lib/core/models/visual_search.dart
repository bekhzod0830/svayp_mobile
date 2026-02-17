/// Visual Search Models
/// Data models for visual search feature

import 'product.dart';

/// Image analysis result from AI
class ImageAnalysisResult {
  final String? clothingItem;
  final String? category;
  final String? subcategory;
  final List<String> colors;
  final List<String> patterns;
  final String? styleCategory;
  final String? fitType;
  final String? coverageLevel;
  final String? sleeveLength;
  final String? length;
  final String? material;
  final String? occasion;
  final String? genderTarget;
  final List<String> styleTags;
  final bool? isHijabAppropriate;
  final double confidence;
  final String rawDescription;

  ImageAnalysisResult({
    this.clothingItem,
    this.category,
    this.subcategory,
    this.colors = const [],
    this.patterns = const [],
    this.styleCategory,
    this.fitType,
    this.coverageLevel,
    this.sleeveLength,
    this.length,
    this.material,
    this.occasion,
    this.genderTarget,
    this.styleTags = const [],
    this.isHijabAppropriate,
    required this.confidence,
    required this.rawDescription,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      clothingItem: json['clothing_item'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      colors:
          (json['colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      patterns:
          (json['patterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      styleCategory: json['style_category'] as String?,
      fitType: json['fit_type'] as String?,
      coverageLevel: json['coverage_level'] as String?,
      sleeveLength: json['sleeve_length'] as String?,
      length: json['length'] as String?,
      material: json['material'] as String?,
      occasion: json['occasion'] as String?,
      genderTarget: json['gender_target'] as String?,
      styleTags:
          (json['style_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isHijabAppropriate: json['is_hijab_appropriate'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawDescription: json['raw_description'] as String? ?? '',
    );
  }
}

/// Match details breakdown
class MatchDetails {
  final double categoryMatch;
  final double colorMatch;
  final double patternMatch;
  final double styleMatch;
  final double coverageMatch;
  final double fitMatch;
  final double sleeveMatch;
  final double lengthMatch;
  final double occasionMatch;
  final double materialMatch;

  MatchDetails({
    required this.categoryMatch,
    required this.colorMatch,
    required this.patternMatch,
    required this.styleMatch,
    required this.coverageMatch,
    required this.fitMatch,
    required this.sleeveMatch,
    required this.lengthMatch,
    required this.occasionMatch,
    required this.materialMatch,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    return MatchDetails(
      categoryMatch: (json['category_match'] as num?)?.toDouble() ?? 0.0,
      colorMatch: (json['color_match'] as num?)?.toDouble() ?? 0.0,
      patternMatch: (json['pattern_match'] as num?)?.toDouble() ?? 0.0,
      styleMatch: (json['style_match'] as num?)?.toDouble() ?? 0.0,
      coverageMatch: (json['coverage_match'] as num?)?.toDouble() ?? 0.0,
      fitMatch: (json['fit_match'] as num?)?.toDouble() ?? 0.0,
      sleeveMatch: (json['sleeve_match'] as num?)?.toDouble() ?? 0.0,
      lengthMatch: (json['length_match'] as num?)?.toDouble() ?? 0.0,
      occasionMatch: (json['occasion_match'] as num?)?.toDouble() ?? 0.0,
      materialMatch: (json['material_match'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get top 3 strongest matches
  List<MapEntry<String, double>> getTopMatches() {
    final matches = {
      'Category': categoryMatch,
      'Color': colorMatch,
      'Pattern': patternMatch,
      'Style': styleMatch,
      'Coverage': coverageMatch,
      'Fit': fitMatch,
      'Sleeve': sleeveMatch,
      'Length': lengthMatch,
      'Occasion': occasionMatch,
      'Material': materialMatch,
    };

    final sorted = matches.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).toList();
  }
}

/// Visual search match (product + similarity score)
class VisualSearchMatch {
  final Product product;
  final double similarityScore;
  final MatchDetails matchDetails;

  VisualSearchMatch({
    required this.product,
    required this.similarityScore,
    required this.matchDetails,
  });

  factory VisualSearchMatch.fromJson(Map<String, dynamic> json) {
    return VisualSearchMatch(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      matchDetails: MatchDetails.fromJson(
        json['match_details'] as Map<String, dynamic>,
      ),
    );
  }

  /// Get similarity percentage (0-100)
  int get similarityPercentage => (similarityScore * 100).round();
}

/// Visual search response
class VisualSearchResponse {
  final ImageAnalysisResult analysis;
  final List<VisualSearchMatch> matches;
  final int totalMatches;
  final int searchTimeMs;

  VisualSearchResponse({
    required this.analysis,
    required this.matches,
    required this.totalMatches,
    required this.searchTimeMs,
  });

  factory VisualSearchResponse.fromJson(Map<String, dynamic> json) {
    return VisualSearchResponse(
      analysis: ImageAnalysisResult.fromJson(
        json['analysis'] as Map<String, dynamic>,
      ),
      matches:
          (json['matches'] as List<dynamic>?)
              ?.map(
                (e) => VisualSearchMatch.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalMatches: json['total_matches'] as int? ?? 0,
      searchTimeMs: json['search_time_ms'] as int? ?? 0,
    );
  }

  /// Get search time in seconds
  double get searchTimeSeconds => searchTimeMs / 1000.0;
}
