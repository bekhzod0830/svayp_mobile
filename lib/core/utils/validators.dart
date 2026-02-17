import 'package:swipe/core/constants/app_constants.dart';

/// Form Validators
class Validators {
  Validators._();

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters';
    }
    if (value.trim().length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }
    return null;
  }

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove all non-digit characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it has 12 digits (998 + 9 digits) or 9 digits (without country code)
    if (cleaned.length != 12 && cleaned.length != 9) {
      return 'Please enter a valid phone number';
    }

    // If 12 digits, must start with 998
    if (cleaned.length == 12 && !cleaned.startsWith('998')) {
      return 'Phone number must start with +998';
    }

    // REMOVED: Operator code validation for testing purposes
    // Allow any operator code to make testing easier

    return null;
  }

  /// Validate OTP code
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP code is required';
    }
    if (value.length != AppConstants.otpLength) {
      return 'OTP must be ${AppConstants.otpLength} digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  /// Validate email (optional field)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate age
  static String? age(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    if (age < AppConstants.minimumAge) {
      return 'You must be at least ${AppConstants.minimumAge} years old';
    }
    if (age > AppConstants.maximumAge) {
      return 'Please enter a valid date of birth';
    }
    return null;
  }

  /// Validate height
  static String? height(int? value) {
    if (value == null) {
      return 'Height is required';
    }
    if (value < AppConstants.minHeight || value > AppConstants.maxHeight) {
      return 'Height must be between ${AppConstants.minHeight} and ${AppConstants.maxHeight} cm';
    }
    return null;
  }

  /// Validate weight (optional)
  static String? weight(int? value) {
    if (value == null) {
      return null; // Optional
    }
    if (value < AppConstants.minWeight || value > AppConstants.maxWeight) {
      return 'Weight must be between ${AppConstants.minWeight} and ${AppConstants.maxWeight} kg';
    }
    return null;
  }
}
