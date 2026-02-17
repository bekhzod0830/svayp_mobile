import 'package:equatable/equatable.dart';

/// User Profile Create Request
class ProfileCreateRequest extends Equatable {
  // Required fields
  final String gender;
  final String dateOfBirth;
  final int heightCm;
  final double weightKg;
  final String bodyType;

  // Optional clothing sizes
  final String? topSize;
  final String? bottomSize;
  final String? dressSize;
  final String? jeanWaistSize;
  final String? shoeSize;
  
  // Bra sizes
  final String? braType;
  final String? braBandSize;
  final String? braCupSize;
  final String? braSupportLevel;

  // Muslim fashion preferences - REQUIRED
  final String hijabPreference; // Required: covered, uncovered, not_applicable
  final List<String>
  fitPreference; // Required: regular, loose, slim, oversized, super_slim (min 1)
  final List<String>
  stylePreference; // Required: revealing, covered (1-2 items)

  // Style preferences - OPTIONAL
  final String? primaryObjective;
  final List<String>? styleCategories;
  final List<String>? occasionPreference; // Added: occasions user dresses for
  final List<String>? brandPreference; // Added: preferred brands
  final List<String>? preferredColors;
  final List<String>? avoidedColors;
  final List<String>? avoidedPatterns;
  final List<String>? avoidedItems;

  // Budget
  final String? budgetType;

  // Personal info (optional)
  final String? fullName;
  final String? email;

  const ProfileCreateRequest({
    required this.gender,
    required this.dateOfBirth,
    required this.fullName,
    required this.heightCm,
    required this.weightKg,
    required this.bodyType,
    required this.hijabPreference,
    required this.fitPreference,
    required this.stylePreference,
    this.topSize,
    this.bottomSize,
    this.dressSize,
    this.jeanWaistSize,
    this.shoeSize,
    this.braType,
    this.braBandSize,
    this.braCupSize,
    this.braSupportLevel,
    this.primaryObjective,
    this.styleCategories,
    this.occasionPreference,
    this.brandPreference,
    this.preferredColors,
    this.avoidedColors,
    this.avoidedPatterns,
    this.avoidedItems,
    this.budgetType,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bodyType': bodyType,
      // Clothing sizes - camelCase for API
      if (topSize != null) 'topSize': topSize,
      if (bottomSize != null) 'bottomSize': bottomSize,
      if (dressSize != null) 'dressSize': dressSize,
      if (jeanWaistSize != null) 'jeanWaistSize': jeanWaistSize,
      if (shoeSize != null) 'shoeSize': shoeSize,
      // Bra sizes
      if (braType != null) 'braType': braType,
      if (braBandSize != null) 'braBandSize': braBandSize,
      if (braCupSize != null) 'braCupSize': braCupSize,
      if (braSupportLevel != null) 'braSupportLevel': braSupportLevel,
      // Preferences
      'hijabPreference': hijabPreference,
      'fitPreference': fitPreference,
      'stylePreference': stylePreference,
      if (primaryObjective != null) 'primaryObjective': primaryObjective,
      if (styleCategories != null) 'styleCategories': styleCategories,
      if (occasionPreference != null) 'occasionPreference': occasionPreference,
      if (brandPreference != null) 'brandPreference': brandPreference,
      if (preferredColors != null) 'preferredColors': preferredColors,
      if (avoidedColors != null) 'avoidedColors': avoidedColors,
      if (avoidedPatterns != null) 'avoidedPatterns': avoidedPatterns,
      if (avoidedItems != null) 'avoidedItems': avoidedItems,
      if (budgetType != null) 'budgetType': budgetType,
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
    };
  }

  @override
  List<Object?> get props => [
    gender,
    dateOfBirth,
    heightCm,
    weightKg,
    bodyType,
    topSize,
    bottomSize,
    dressSize,
    jeanWaistSize,
    shoeSize,
    braType,
    braBandSize,
    braCupSize,
    braSupportLevel,
    hijabPreference,
    fitPreference,
    stylePreference,
    primaryObjective,
    styleCategories,
    occasionPreference,
    brandPreference,
    preferredColors,
    avoidedColors,
    avoidedPatterns,
    avoidedItems,
    budgetType,
    fullName,
    email,
  ];
}

/// User Event Request (for swipe actions, views, etc.)
class UserEventRequest extends Equatable {
  final String productId;
  final String eventType;
  final String? swipeAction;
  final int? viewDurationMs;
  final int? rating;
  final Map<String, dynamic>? context;

  const UserEventRequest({
    required this.productId,
    required this.eventType,
    this.swipeAction,
    this.viewDurationMs,
    this.rating,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'event_type': eventType,
      if (swipeAction != null) 'swipe_action': swipeAction,
      if (viewDurationMs != null) 'view_duration_ms': viewDurationMs,
      if (rating != null) 'rating': rating,
      if (context != null) 'context': context,
    };
  }

  @override
  List<Object?> get props => [
    productId,
    eventType,
    swipeAction,
    viewDurationMs,
    rating,
    context,
  ];
}

/// Batch User Events Request
class BatchUserEventsRequest extends Equatable {
  final List<UserEventRequest> events;

  const BatchUserEventsRequest({required this.events});

  Map<String, dynamic> toJson() {
    return {'events': events.map((e) => e.toJson()).toList()};
  }

  @override
  List<Object?> get props => [events];
}

/// User Profile Response (from GET /users/profile)
class UserProfileResponse extends Equatable {
  final String id;
  final String userId;
  final String gender;
  final int? age;
  final int? heightCm;
  final String? bodyType;
  final String hijabPreference;
  final List<String>? styleCategories;
  final int? budgetMin;
  final int? budgetMax;
  final bool styleQuizCompleted;
  final DateTime createdAt;

  const UserProfileResponse({
    required this.id,
    required this.userId,
    required this.gender,
    this.age,
    this.heightCm,
    this.bodyType,
    required this.hijabPreference,
    this.styleCategories,
    this.budgetMin,
    this.budgetMax,
    required this.styleQuizCompleted,
    required this.createdAt,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gender: json['gender'] as String,
      age: json['age'] as int?,
      heightCm: json['height_cm'] as int?,
      bodyType: json['body_type'] as String?,
      hijabPreference: json['hijab_preference'] as String,
      styleCategories: json['style_categories'] != null
          ? List<String>.from(json['style_categories'] as List)
          : null,
      budgetMin: json['budget_min'] as int?,
      budgetMax: json['budget_max'] as int?,
      styleQuizCompleted: json['style_quiz_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    gender,
    age,
    heightCm,
    bodyType,
    hijabPreference,
    styleCategories,
    budgetMin,
    budgetMax,
    styleQuizCompleted,
    createdAt,
  ];
}
