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

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      coId: json['co_id']?.toString() ?? '',
      firstName: json['co_first_name'] as String?,
      lastName: json['co_last_name'] as String?,
      avatar: json['co_avatar'] as String?,
      specialty: json['co_specialty'] as String?,
      rating: (json['co_rating'] as num?)?.toDouble(),
      pricePerMinute: (json['co_price_per_minute'] as num?)?.toDouble(),
      isOnline: json['co_is_online'] as bool?,
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
      firstName: json['co_first_name'] as String?,
      lastName: json['co_last_name'] as String?,
      avatar: json['co_avatar'] as String?,
      specialty: json['co_specialty'] as String?,
      rating: (json['co_rating'] as num?)?.toDouble(),
      pricePerMinute: (json['co_price_per_minute'] as num?)?.toDouble(),
      isOnline: json['co_is_online'] as bool?,
      description: json['co_description'] as String?,
      phone: json['co_phone'] as String?,
      email: json['co_email'] as String?,
    );
  }
}
