class Professional {
  final String coId;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? specialty;
  final List<String> specialties;
  final List<String> languages;
  final double? rating;
  final double? pricePerMinute;
  final double? pricePhonePerMinute;
  final double? priceVideoPerMinute;
  final double? priceChatPerMinute;
  final bool? isOnline;
  final bool supportsPhone;
  final bool supportsVideo;
  final bool supportsChat;
  final bool isRecommended;
  final bool isFavorite;
  final int? experienceYears;
  final bool isVerified;
  final bool isAvailableNow;
  final String? availabilityText;

  const Professional({
    required this.coId,
    this.firstName,
    this.lastName,
    this.avatar,
    this.specialty,
    this.specialties = const [],
    this.languages = const [],
    this.rating,
    this.pricePerMinute,
    this.pricePhonePerMinute,
    this.priceVideoPerMinute,
    this.priceChatPerMinute,
    this.isOnline,
    this.supportsPhone = false,
    this.supportsVideo = false,
    this.supportsChat = false,
    this.isRecommended = false,
    this.isFavorite = false,
    this.experienceYears,
    this.isVerified = false,
    this.isAvailableNow = false,
    this.availabilityText,
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
        // Check for timestamp fields (co_profile_verified_at, etc.)
        if (normalized.isNotEmpty && normalized != '0000-00-00 00:00:00') {
          return true;
        }
      }
    }
    return null;
  }

  static List<String> _readStringList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is List) {
        final result = <String>[];
        for (final item in value) {
          if (item == null) continue;
          if (item is String) {
            final text = item.trim();
            if (text.isNotEmpty) result.add(text);
            continue;
          }
          if (item is Map<String, dynamic>) {
            final text = _readString(item, [
              'name',
              'label',
              'value',
              'title',
              'la_name',
              'sp_name',
              'speciality',
            ]);
            if (text != null && text.isNotEmpty) result.add(text);
          }
        }
        if (result.isNotEmpty) return result;
      }

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) continue;
        final split = trimmed
            .split(RegExp(r'[,;|]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (split.isNotEmpty) return split;
      }
    }
    return const [];
  }

  static double? _normalizePrice(double? value) {
    if (value == null) return null;
    // Backend often returns cents (e.g. 150 => 1.50 EUR/min).
    return value > 20 ? value / 100 : value;
  }

  static int? _readExperienceYears(Map<String, dynamic> json) {
    final started = _readString(json, ['co_activity_started', 'createdAt']);
    if (started == null || started.isEmpty) return null;

    final date = DateTime.tryParse(started);
    if (date == null) return null;

    final now = DateTime.now();
    var years = now.year - date.year;
    if (DateTime(now.year, date.month, date.day).isAfter(now)) {
      years -= 1;
    }
    return years < 0 ? 0 : years;
  }

  factory Professional.fromJson(Map<String, dynamic> json) {
    final firstName = _readString(json, ['co_first_name', 'co_firstname']);
    final lastName = _readString(json, [
      'co_last_name',
      'co_name',
      'co_lastname',
    ]);

    final pricePhone = _normalizePrice(
      _readDouble(json, ['co_price_phone', 'price_phone']),
    );
    final priceVideo = _normalizePrice(
      _readDouble(json, ['co_price_video', 'price_video']),
    );
    final priceChat = _normalizePrice(
      _readDouble(json, ['co_price_chat', 'price_chat']),
    );

    final fallbackPrice = _normalizePrice(
      _readDouble(json, ['co_price_per_minute', 'co_price', 'co_fees']),
    );
    final prices = [
      pricePhone,
      priceVideo,
      priceChat,
    ].whereType<double>().where((p) => p > 0).toList();

    final specialties = _readStringList(json, [
      'co_specialities',
      'co_specialty',
      'co_subtype',
    ]);
    final languages = _readStringList(json, ['co_languages', 'languages']);

    final online = _readBool(json, ['co_is_online', 'co_online', 'is_online']);
    final availableNow = _readBool(json, ['disponibilityNow']) ?? online ?? false;

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
      specialties: specialties,
      languages: languages,
      rating: _readDouble(json, [
        'co_rating',
        'co_rating_average',
        'co_calculatednote',
        'rating',
      ]),
      pricePerMinute: prices.isNotEmpty
          ? prices.reduce((a, b) => a < b ? a : b)
          : fallbackPrice,
      pricePhonePerMinute: pricePhone,
      priceVideoPerMinute: priceVideo,
      priceChatPerMinute: priceChat,
      isOnline: online,
      supportsPhone:
          _readBool(json, ['co_use_phone', 'use_phone']) ??
          (pricePhone ?? 0) > 0,
      supportsVideo:
          _readBool(json, ['co_use_video', 'use_video']) ??
          (priceVideo ?? 0) > 0,
      supportsChat:
          _readBool(json, ['co_use_chat', 'use_chat']) ?? (priceChat ?? 0) > 0,
      isRecommended:
          _readBool(json, ['co_recommended', 'recommended']) ?? false,
      isFavorite: _readBool(json, ['co_favorite', 'favorite']) ?? false,
      experienceYears: _readExperienceYears(json),
      isVerified: _readBool(json, ['co_profile_verified_at']) ?? false,
      isAvailableNow: availableNow,
      availabilityText: _readString(json, ['disponibilityText']),
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
    super.pricePhonePerMinute,
    super.priceVideoPerMinute,
    super.priceChatPerMinute,
    super.isOnline,
    super.isVerified,
    super.isAvailableNow,
    super.availabilityText,
    super.isFavorite,
    super.supportsPhone,
    super.supportsVideo,
    super.supportsChat,
    this.description,
    this.phone,
    this.email,
  });

  factory ProfessionalDetail.fromJson(Map<String, dynamic> json) {
    final pricePhone = Professional._normalizePrice(
      Professional._readDouble(json, ['co_price_phone', 'price_phone']),
    );
    final priceVideo = Professional._normalizePrice(
      Professional._readDouble(json, ['co_price_video', 'price_video']),
    );
    final priceChat = Professional._normalizePrice(
      Professional._readDouble(json, ['co_price_chat', 'price_chat']),
    );
    final fallbackPrice = Professional._normalizePrice(
      Professional._readDouble(json, [
        'co_price_per_minute',
        'co_price',
        'co_fees',
      ]),
    );

    final online = Professional._readBool(json, [
      'co_is_online',
      'co_online',
      'is_online',
    ]);
    final availableNow =
        Professional._readBool(json, ['disponibilityNow']) ?? online ?? false;

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
        'co_calculatednote',
        'rating',
      ]),
      pricePerMinute: fallbackPrice,
      pricePhonePerMinute: pricePhone,
      priceVideoPerMinute: priceVideo,
      priceChatPerMinute: priceChat,
      isOnline: online,
      description: Professional._readString(json, [
        'co_description',
        'co_presentation',
        'co_bio',
      ]),
      phone: Professional._readString(json, ['co_phone', 'co_mobile']),
      email: json['co_email'] as String?,
      isVerified:
          Professional._readBool(json, ['co_profile_verified_at']) ?? false,
        isAvailableNow: availableNow,
      availabilityText: Professional._readString(json, ['disponibilityText']),
      isFavorite:
          Professional._readBool(json, ['co_favorite', 'favorite']) ?? false,
      supportsPhone:
          Professional._readBool(json, ['co_use_phone', 'use_phone']) ??
          (pricePhone ?? 0) > 0,
      supportsVideo:
          Professional._readBool(json, ['co_use_video', 'use_video']) ??
          (priceVideo ?? 0) > 0,
      supportsChat:
          Professional._readBool(json, ['co_use_chat', 'use_chat']) ??
          (priceChat ?? 0) > 0,
    );
  }
}
