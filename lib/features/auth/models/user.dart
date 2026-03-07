import 'package:voyanz/features/auth/models/agency.dart';

class User {
  final String coId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role; // 'customer' | 'professional'
  final String? phone;
  final String? avatar;

  const User({
    required this.coId,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.phone,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      coId: json['co_id']?.toString() ?? '',
      email: json['co_email'] as String?,
      firstName: json['co_first_name'] as String?,
      lastName: json['co_last_name'] as String?,
      role: json['co_role'] as String?,
      phone: json['co_phone'] as String?,
      avatar: json['co_avatar'] as String?,
    );
  }
}

/// Full payload returned by POST /api/1.0/login.
class LoginResponse {
  final User user;
  final String accessToken;
  final String? refreshToken;
  final Agency? agency;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? i18n;

  const LoginResponse({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.agency,
    this.preferences,
    this.i18n,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
      accessToken: json['accesstoken'] as String? ?? '',
      refreshToken: json['refreshtoken'] as String?,
      agency: json['agency'] != null
          ? Agency.fromJson(json['agency'] as Map<String, dynamic>)
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
      i18n: json['i18n'] as Map<String, dynamic>?,
    );
  }
}
