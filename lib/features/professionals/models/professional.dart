class Professional {
  final String coId;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? specialty;
  final String? bio;
  final List<String> specialties;
  final List<String> tools;
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
  final bool isAssistant;

  const Professional({
    required this.coId,
    this.firstName,
    this.lastName,
    this.avatar,
    this.specialty,
    this.bio,
    this.specialties = const [],
    this.tools = const [],
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
    this.isAssistant = false,
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
      if (value is Map<String, dynamic>) {
        final nested = _readDouble(value, [
          'note',
          'rating',
          'average',
          'avg',
          'value',
        ]);
        if (nested != null) return nested;
      }
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
              'val',
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

  static bool? _inferAvailabilityFromText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.toLowerCase();

    if (text.contains('no availability') ||
        text.contains('not available') ||
        text.contains('indisponible') ||
        text.contains('pas disponible')) {
      return false;
    }

    if (text.contains('available now') ||
        text.contains('disponible') ||
        text.contains('available')) {
      return true;
    }

    return null;
  }

  factory Professional.fromJson(Map<String, dynamic> json) {
    // `co_name` is the legal surname while `co_fullname` is the public name
    // shown by Voyanz. Never append the former to the latter (for example,
    // the website displays "Melli", not "Melli vogt").
    final publicName = _readString(json, ['co_fullname']);
    final firstName =
        publicName ?? _readString(json, ['co_first_name', 'co_firstname']);
    final lastName = publicName == null
        ? _readString(json, ['co_last_name', 'co_name', 'co_lastname'])
        : null;

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
      'co_speciality',
      'co_specialty',
      'specialities',
      'speciality',
      'co_subtype',
    ]);
    final languages = _readStringList(json, ['co_languages', 'languages']);
    final tools = _readStringList(json, ['co_tools', 'tools']);

    final online = _readBool(json, ['co_is_online', 'co_online', 'is_online']);
    final availabilityText = _readString(json, ['disponibilityText']);
    final availableNow =
        _readBool(json, ['disponibilityNow']) ??
        _readBool(json, ['is_available_now', 'availability_now']) ??
        _inferAvailabilityFromText(availabilityText) ??
        false;

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
      bio: _readString(json, ['co_description', 'co_presentation', 'co_bio']),
      specialties: specialties,
      tools: tools,
      languages: languages,
      rating: _readDouble(json, [
        'co_rating',
        'co_rating_average',
        'co_calculatednote',
        'reviewsNote',
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
      availabilityText: availabilityText,
      isAssistant: _readBool(json, ['co_isassistant', 'is_assistant']) ?? false,
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
    super.bio,
    super.specialties,
    super.tools,
    super.languages,
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
    super.isRecommended,
    super.experienceYears,
    super.supportsPhone,
    super.supportsVideo,
    super.supportsChat,
    super.isAssistant,
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
    final availabilityText = Professional._readString(json, [
      'disponibilityText',
    ]);
    final availableNow =
        Professional._readBool(json, ['disponibilityNow']) ??
        Professional._readBool(json, [
          'is_available_now',
          'availability_now',
        ]) ??
        Professional._inferAvailabilityFromText(availabilityText) ??
        false;

    final publicName = Professional._readString(json, ['co_fullname']);

    return ProfessionalDetail(
      coId: json['co_id']?.toString() ?? '',
      firstName:
          publicName ??
          Professional._readString(json, ['co_first_name', 'co_firstname']),
      lastName: publicName == null
          ? Professional._readString(json, [
              'co_last_name',
              'co_name',
              'co_lastname',
            ])
          : null,
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
      specialties: Professional._readStringList(json, [
        'co_specialities',
        'co_speciality',
        'co_specialty',
        'specialities',
        'speciality',
      ]),
      tools: Professional._readStringList(json, ['co_tools', 'tools']),
      languages: Professional._readStringList(json, [
        'co_languages',
        'languages',
      ]),
      rating: Professional._readDouble(json, [
        'co_rating',
        'co_rating_average',
        'co_calculatednote',
        'reviewsNote',
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
      availabilityText: availabilityText,
      isFavorite:
          Professional._readBool(json, ['co_favorite', 'favorite']) ?? false,
      isRecommended:
          Professional._readBool(json, ['co_recommended', 'recommended']) ??
          false,
      experienceYears: Professional._readExperienceYears(json),
      supportsPhone:
          Professional._readBool(json, ['co_use_phone', 'use_phone']) ??
          (pricePhone ?? 0) > 0,
      supportsVideo:
          Professional._readBool(json, ['co_use_video', 'use_video']) ??
          (priceVideo ?? 0) > 0,
      supportsChat:
          Professional._readBool(json, ['co_use_chat', 'use_chat']) ??
          (priceChat ?? 0) > 0,
      isAssistant:
          Professional._readBool(json, ['co_isassistant', 'is_assistant']) ??
          false,
    );
  }

  /// The detail endpoint intentionally returns a compact contact object.
  /// Enrich it with the matching object from `/professionals`, which is where
  /// the public bio, tools, specialties, languages and assistant marker live.
  ProfessionalDetail withListFallback(Professional fallback) {
    String? preferText(String? primary, String? secondary) {
      return primary == null || primary.trim().isEmpty ? secondary : primary;
    }

    double? preferPrice(double? primary, double? secondary) {
      return primary ?? secondary;
    }

    return ProfessionalDetail(
      coId: coId.isEmpty ? fallback.coId : coId,
      firstName: preferText(firstName, fallback.firstName),
      lastName: preferText(lastName, fallback.lastName),
      avatar: preferText(avatar, fallback.avatar),
      specialty:
          specialty == null ||
              specialty!.trim().isEmpty ||
              specialty!.trim().toLowerCase() == 'professional'
          ? (fallback.specialty ??
                (fallback.specialties.isEmpty
                    ? null
                    : fallback.specialties.first))
          : specialty,
      specialties: specialties.isEmpty ? fallback.specialties : specialties,
      tools: tools.isEmpty ? fallback.tools : tools,
      languages: languages.isEmpty ? fallback.languages : languages,
      rating: rating ?? fallback.rating,
      pricePerMinute: preferPrice(pricePerMinute, fallback.pricePerMinute),
      pricePhonePerMinute: preferPrice(
        pricePhonePerMinute,
        fallback.pricePhonePerMinute,
      ),
      priceVideoPerMinute: preferPrice(
        priceVideoPerMinute,
        fallback.priceVideoPerMinute,
      ),
      priceChatPerMinute: preferPrice(
        priceChatPerMinute,
        fallback.priceChatPerMinute,
      ),
      isOnline: isOnline ?? fallback.isOnline,
      isVerified: isVerified || fallback.isVerified,
      isAvailableNow: isAvailableNow || fallback.isAvailableNow,
      availabilityText: preferText(availabilityText, fallback.availabilityText),
      isFavorite: isFavorite || fallback.isFavorite,
      isRecommended: isRecommended || fallback.isRecommended,
      experienceYears: experienceYears ?? fallback.experienceYears,
      supportsPhone: supportsPhone || fallback.supportsPhone,
      supportsVideo: supportsVideo || fallback.supportsVideo,
      supportsChat: supportsChat || fallback.supportsChat,
      isAssistant: isAssistant || fallback.isAssistant,
      description: preferText(description, fallback.bio),
      phone: phone,
      email: email,
    );
  }
}
