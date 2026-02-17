import 'package:equatable/equatable.dart';

/// User Response Model
class UserResponse extends Equatable {
  final String id;
  final String phoneNumber;
  final String? fullName;
  final String? avatarUrl;
  final String? email;
  final String role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final bool hasProfile;

  const UserResponse({
    required this.id,
    required this.phoneNumber,
    this.fullName,
    this.avatarUrl,
    this.email,
    this.role = 'USER',
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.hasProfile,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'CLIENT',
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      hasProfile: json['has_profile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'email': email,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'has_profile': hasProfile,
    };
  }

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    fullName,
    avatarUrl,
    email,
    role,
    isActive,
    isVerified,
    createdAt,
    hasProfile,
  ];
}

/// Token Response Model
class TokenResponse extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String tokenType;
  final UserResponse user;

  const TokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    required this.tokenType,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    // Handle ApiResponse wrapper
    final data = json['data'] ?? json;
    
    return TokenResponse(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      expiresIn: data['expires_in'] as int?,
      tokenType: data['token_type'] as String? ?? 'bearer',
      user: UserResponse.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn, tokenType, user];
}

/// Message Response Model (for simple success messages)
class MessageResponse extends Equatable {
  final String message;
  final int? expiresIn;
  final bool success;

  const MessageResponse({
    required this.message, 
    this.expiresIn,
    this.success = true,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    // Message is at root level
    final message = json['message'] as String? ?? 'Success';
    
    // Data contains additional fields like expires_in_seconds
    final data = json['data'];
    int? expiresIn;
    if (data != null && data is Map<String, dynamic>) {
      expiresIn = data['expires_in_seconds'] as int? ?? 
                  data['expires_in'] as int? ?? 
                  data['expiresIn'] as int?;
    }
    
    return MessageResponse(
      message: message,
      expiresIn: expiresIn,
      success: json['success'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'expires_in': expiresIn,
      'success': success,
    };
  }

  @override
  List<Object?> get props => [message, expiresIn, success];
}
