import 'package:voyanz/features/auth/models/agency.dart';

class User {
  final String coId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role; // 'customer' | 'professional'
  final String? phone;
  final String? avatar;

  bool get isProfessional => role == 'professional';

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
    final rawRole =
        json['co_role'] ??
        json['co_role_label'] ??
        json['co_type_label'] ??
        json['co_type'] ??
        json['role'] ??
        json['user_type'];

    return User(
      coId: json['co_id']?.toString() ?? '',
      email: json['co_email'] as String?,
      firstName: json['co_first_name'] as String?,
      lastName: json['co_last_name'] as String?,
      role: _normalizeRole(rawRole),
      phone: json['co_phone'] as String?,
      avatar: json['co_avatar'] as String?,
    );
  }

  static String _normalizeRole(dynamic value) {
    if (value is num) {
      // Common role codes used by some backends.
      if (value == 2) return 'professional';
      if (value == 1 || value == 0) return 'customer';
    }

    final role = value?.toString().trim().toLowerCase() ?? '';

    if (role == '2') return 'professional';
    if (role == '1' || role == '0') return 'customer';

    if (role.isEmpty) return 'customer';

    // Normalize common backend variants.
    if (role == 'professional' || role == 'pro' || role == 'advisor') {
      return 'professional';
    }

    if (role == 'customer' || role == 'client' || role == 'user') {
      return 'customer';
    }

    return role;
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
