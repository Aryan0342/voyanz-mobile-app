import 'package:voyanz/features/auth/models/agency.dart';

class User {
  final String coId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role; // 'customer' | 'professional'
  final String? phone;
  final String? avatar;
  final double? credit;
  final String? siret;

  /// `co_online` for a professional: 1 = online, 0 = offline, 2 = busy.
  /// Null when the backend did not send it.
  final int? online;

  bool get isProfessional => role == 'professional';

  const User({
    required this.coId,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.phone,
    this.avatar,
    this.credit,
    this.siret,
    this.online,
  });

  User copyWith({double? credit, int? online}) => User(
        coId: coId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phone: phone,
        avatar: avatar,
        credit: credit ?? this.credit,
        siret: siret,
        online: online ?? this.online,
      );

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
      online: _toInt(json['co_online'] ?? json['online'] ?? json['is_online']),
      email:
          json['co_email'] as String? ??
          json['co_email1'] as String? ??
          json['email'] as String?,
      firstName:
          json['co_first_name'] as String? ??
          json['co_firstname'] as String? ??
          json['co_fullname'] as String? ??
          json['firstname'] as String?,
      lastName:
          json['co_last_name'] as String? ??
          json['co_name'] as String? ??
          json['lastname'] as String?,
      role: _normalizeRole(rawRole),
      phone:
          json['co_phone'] as String? ??
          json['co_mobile'] as String? ??
          json['co_mobile1'] as String?,
      avatar: json['co_avatar'] as String?,
      siret:
          json['co_siret'] as String? ??
          json['co_immatriculation'] as String? ??
          json['siret'] as String?,
      credit: _parseCredit(json),
    );
  }

  static double? _parseCredit(Map<String, dynamic> json) {
    const keys = [
      'co_credit',
      'credit',
      'balance',
      'wallet',
      'customer_credit',
    ];

    for (final key in keys) {
      final parsed = _toDouble(json[key]);
      if (parsed != null) return parsed;
    }

    final account = json['account'];
    if (account is Map<String, dynamic>) {
      for (final key in keys) {
        final parsed = _toDouble(account[key]);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static double? _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    final text = raw?.toString() ?? '';
    if (text.isEmpty) return null;
    final normalized = text
        .replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
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

  /// Allowed values for the professional profile (contract P1). The server
  /// sends either an object keyed by list name or a flat list of rows, so it
  /// is kept raw and normalised by `CatalogItems`.
  final dynamic items;

  const LoginResponse({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.agency,
    this.preferences,
    this.i18n,
    this.items,
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
      items: json['items'],
    );
  }
}
