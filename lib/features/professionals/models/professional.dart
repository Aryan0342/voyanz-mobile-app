class Professional {
  final String coId;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? specialty;
  final double? rating;
  final double? pricePerMinute;
  final bool? isOnline;

  const Professional({
    required this.coId,
    this.firstName,
    this.lastName,
    this.avatar,
    this.specialty,
    this.rating,
    this.pricePerMinute,
    this.isOnline,
  });

  String get displayName =>
      '${firstName ?? ''} ${lastName ?? ''}'.trim().isEmpty
      ? 'Professional'
      : '${firstName ?? ''} ${lastName ?? ''}'.trim();

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is Map<String, dynamic>) {
        final nested =
            value['url'] ??
            value['src'] ??
            value['path'] ??
            value['value'] ??
            value['original'];
        if (nested != null) {
          final nestedText = nested.toString().trim();
          if (nestedText.isNotEmpty) return nestedText;
        }
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return null;
  }

  factory Professional.fromJson(Map<String, dynamic> json) {
    final firstName = _readString(json, ['co_first_name', 'co_firstname']);
    final lastName = _readString(json, [
      'co_last_name',
      'co_name',
      'co_lastname',
    ]);

    return Professional(
      coId: json['co_id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      avatar: _readString(json, [
        'co_avatar',
        'co_avatar_url',
        'co_photo',
        'co_picture',
        'co_picture_url',
        'co_image',
        'co_photo_url',
      ]),
      specialty: _readString(json, [
        'co_specialty',
        'co_subtype',
        'co_type_label',
        'co_type',
      ]),
      rating: _readDouble(json, ['co_rating', 'co_rating_average', 'rating']),
      pricePerMinute: _readDouble(json, [
        'co_price_per_minute',
        'co_price',
        'co_fees',
      ]),
      isOnline: _readBool(json, ['co_is_online', 'co_online', 'is_online']),
    );
  }
}

class ProfessionalDetail extends Professional {
  final String? description;
  final String? phone;
  final String? email;

  ProfessionalDetail({
    required super.coId,
    super.firstName,
    super.lastName,
    super.avatar,
    super.specialty,
    super.rating,
    super.pricePerMinute,
    super.isOnline,
    this.description,
    this.phone,
    this.email,
  });

  factory ProfessionalDetail.fromJson(Map<String, dynamic> json) {
    return ProfessionalDetail(
      coId: json['co_id']?.toString() ?? '',
      firstName: Professional._readString(json, [
        'co_first_name',
        'co_firstname',
      ]),
      lastName: Professional._readString(json, [
        'co_last_name',
        'co_name',
        'co_lastname',
      ]),
      avatar: Professional._readString(json, [
        'co_avatar',
        'co_avatar_url',
        'co_photo',
        'co_picture',
        'co_picture_url',
        'co_image',
        'co_photo_url',
      ]),
      specialty: Professional._readString(json, [
        'co_specialty',
        'co_subtype',
        'co_type_label',
        'co_type',
      ]),
      rating: Professional._readDouble(json, [
        'co_rating',
        'co_rating_average',
        'rating',
      ]),
      pricePerMinute: Professional._readDouble(json, [
        'co_price_per_minute',
        'co_price',
        'co_fees',
      ]),
      isOnline: Professional._readBool(json, [
        'co_is_online',
        'co_online',
        'is_online',
      ]),
      description: Professional._readString(json, [
        'co_description',
        'co_presentation',
        'co_bio',
      ]),
      phone: Professional._readString(json, ['co_phone', 'co_mobile']),
      email: json['co_email'] as String?,
    );
  }
}
