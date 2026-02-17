import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';
import 'package:swipe/features/profile/data/models/profile_models.dart';
import 'package:swipe/features/auth/data/models/auth_models.dart';

/// Profile Service
/// Handles all profile-related API calls
class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  /// Create user profile
  ///
  /// Creates a new user profile with required and optional information
  /// This should be called after successful OTP verification
  ///
  /// Example:
  /// ```dart
  /// final request = ProfileCreateRequest(
  ///   gender: 'female',
  ///   dateOfBirth: '2000-01-15',
  ///   heightCm: 165,
  ///   weightKg: 55.0,
  ///   bodyType: 'hourglass',
  ///   hijabPreference: 'covered',
  /// );
  /// await profileService.createProfile(request);
  /// ```
  Future<MessageResponse> createProfile(ProfileCreateRequest request) async {
    try {
      await _apiClient.post(ApiConfig.userProfile, data: request.toJson());

      // Backend returns UserProfileResponse, but we just need to confirm success
      // Return a simple success message instead of parsing the full response
      return const MessageResponse(
        message: 'Profile created successfully',
        success: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile
  ///
  /// Retrieves the current user's complete profile from the backend
  ///
  /// Example:
  /// ```dart
  /// final profile = await profileService.getProfile();
  /// print('Gender: ${profile.gender}');
  /// print('Budget: ${profile.budgetMin} - ${profile.budgetMax}');
  /// ```
  Future<UserProfileResponse> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConfig.userProfile);
      
      // Handle wrapped response
      final data = response.data['data'] ?? response.data;
      return UserProfileResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  ///
  /// Updates existing user profile with new information
  ///
  /// Example:
  /// ```dart
  /// await profileService.updateProfile({
  ///   'full_name': 'Jane Doe',
  ///   'email': 'jane@example.com',
  /// });
  /// ```
  Future<MessageResponse> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.updateProfile,
        data: data,
      );

      return MessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Record a user event (swipe, view, etc.)
  ///
  /// Records a single user interaction event
  ///
  /// Example:
  /// ```dart
  /// final event = UserEventRequest(
  ///   productId: 'product_123',
  ///   eventType: 'swipe',
  ///   swipeAction: 'like',
  /// );
  /// await profileService.recordEvent(event);
  /// ```
  Future<MessageResponse> recordEvent(UserEventRequest event) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.userEvents,
        data: event.toJson(),
      );

      return MessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Record multiple user events in batch
  ///
  /// Records multiple user interaction events at once
  /// This is more efficient than recording events one by one
  ///
  /// Example:
  /// ```dart
  /// final events = [
  ///   UserEventRequest(
  ///     productId: 'product_1',
  ///     eventType: 'swipe',
  ///     swipeAction: 'like',
  ///   ),
  ///   UserEventRequest(
  ///     productId: 'product_2',
  ///     eventType: 'swipe',
  ///     swipeAction: 'dislike',
  ///   ),
  /// ];
  /// await profileService.recordEventsBatch(events);
  /// ```
  Future<MessageResponse> recordEventsBatch(
    List<UserEventRequest> events,
  ) async {
    try {
      // Backend expects a list directly, not wrapped in an object
      final eventsJson = events.map((e) => e.toJson()).toList();
      final response = await _apiClient.post(
        ApiConfig.userEventsBatch,
        data: eventsJson,
      );

      return MessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Submit style quiz results
  ///
  /// Records all swipe actions from the style quiz
  /// This helps train the AI recommendation system
  ///
  /// Example:
  /// ```dart
  /// final quizResults = [
  ///   {'productId': 'prod_1', 'action': 'like'},
  ///   {'productId': 'prod_2', 'action': 'dislike'},
  ///   {'productId': 'prod_3', 'action': 'like'},
  /// ];
  /// await profileService.submitStyleQuiz(quizResults);
  /// ```
  Future<MessageResponse> submitStyleQuiz(
    List<Map<String, dynamic>> quizResults,
  ) async {
    try {
      // Convert quiz results to user events
      final events = quizResults.map((result) {
        return UserEventRequest(
          productId: result['productId'] as String,
          eventType: 'swipe',
          swipeAction: result['action'] as String,
          context: {
            'source': 'style_quiz',
            'completed_at': DateTime.now().toIso8601String(),
          },
        );
      }).toList();

      // Submit all events in batch
      return await recordEventsBatch(events);
    } catch (e) {
      rethrow;
    }
  }
}
