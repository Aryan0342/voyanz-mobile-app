/// `GET /web/1.0/professional/profile` (contract P1).
///
/// Everything the professional edit screen needs, readable before activation
/// and before the CGS have been accepted.
class ProfessionalProfile {
  final String fullName;
  final String description;
  final String activityStarted; // YYYY-MM-DD
  final bool usePhone;
  final bool useVideo;
  final bool useChat;

  /// Prices in cents, as the server stores them.
  final int pricePhoneCents;
  final int priceVideoCents;
  final int priceChatCents;

  final List<String> languages;
  final List<String> tools;
  final List<String> specialities;

  final bool hasPhoto;
  final bool active;

  /// Raw `co_online` (0 unavailable, 1 available, 2 in session). This is the
  /// only endpoint that reports it: neither the login payload nor
  /// `GET /user/infos` carries it, so the dashboard switch has to be seeded
  /// from here or it always starts on "offline".
  final int? online;
  final bool cgsAccepted;
  final bool stripePayoutsEnabled;

  /// The same checklist the website dashboard shows, when the server sends it.
  final Map<String, bool> completion;

  const ProfessionalProfile({
    this.fullName = '',
    this.description = '',
    this.activityStarted = '',
    this.usePhone = false,
    this.useVideo = false,
    this.useChat = false,
    this.pricePhoneCents = 0,
    this.priceVideoCents = 0,
    this.priceChatCents = 0,
    this.languages = const [],
    this.tools = const [],
    this.specialities = const [],
    this.hasPhoto = false,
    this.active = false,
    this.online,
    this.cgsAccepted = true,
    this.stripePayoutsEnabled = false,
    this.completion = const {},
  });

  bool get hasAnyPrice =>
      pricePhoneCents > 0 || priceVideoCents > 0 || priceChatCents > 0;

  /// Euro value for an edit field (the server stores cents, P1).
  static double centsToEuros(int cents) => cents / 100;

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return ProfessionalProfile(
      fullName: _str(data, ['co_fullname', 'fullname']),
      description: _str(data, ['co_description', 'description']),
      activityStarted: _str(data, ['co_activity_started', 'activity_started']),
      usePhone: _bool(data, ['co_use_phone', 'use_phone']),
      useVideo: _bool(data, ['co_use_video', 'use_video']),
      useChat: _bool(data, ['co_use_chat', 'use_chat']),
      pricePhoneCents: _int(data, ['co_price_phone', 'price_phone']),
      priceVideoCents: _int(data, ['co_price_video', 'price_video']),
      priceChatCents: _int(data, ['co_price_chat', 'price_chat']),
      languages: _list(data, ['co_languages', 'languages']),
      tools: _list(data, ['co_tools', 'tools']),
      specialities: _list(data, ['co_specialities', 'specialities']),
      hasPhoto: _bool(data, ['has_photo', 'co_has_photo']),
      active: _bool(data, ['co_active', 'active']),
      online: _intOrNull(data, ['co_online', 'online']),
      cgsAccepted: _bool(data, ['cgs_accepted']),
      stripePayoutsEnabled: _bool(data, [
        'stripe_payouts_enabled',
        'payouts_enabled',
      ]),
      completion: _completion(data['completion'] ?? data['checklist']),
    );
  }

  /// Distinguishes "the server said 0" from "the server did not say", so a
  /// missing field never claims the professional is offline.
  static int? _intOrNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _str(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static bool _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value.toString().toLowerCase().trim();
      if (text == 'true' || text == '1') return true;
      if (text == 'false' || text == '0') return false;
    }
    return false;
  }

  static int _int(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static List<String> _list(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        final items = <String>[];
        for (final item in value) {
          if (item == null) continue;
          if (item is Map) {
            final key = item['li_key'] ?? item['key'] ?? item['value'];
            if (key != null) items.add(key.toString());
            continue;
          }
          final text = item.toString().trim();
          if (text.isNotEmpty) items.add(text);
        }
        if (items.isNotEmpty) return items;
      }
    }
    return const [];
  }

  static Map<String, bool> _completion(dynamic raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value == true || entry.value == 1,
    };
  }
}
