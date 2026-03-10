/// Central registry of every REST endpoint the mobile app consumes.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = '/api/1.0/login';
  static const String userInfos = '/web/1.0/user/infos';

  // ── Account ────────────────────────────────────────────────────────────
  static const String createAccount = '/web/1.0/account';
  static String updateAccount(String coId) => '/web/1.0/account/$coId';
  static String updateProDescription(String coId) =>
      '/web/1.0/account/description/$coId';

  // ── Professionals ──────────────────────────────────────────────────────
  static const String professionals = '/web/1.0/professionals';
  static String professionalInfos(String coId) =>
      '/web/1.0/professional/$coId/infos';
  static String professionalFavorite(String coId) =>
      '/web/1.0/professional/favorite/$coId';
  static const String professionalDisponibilities =
      '/web/1.0/professional/disponibilities';
  static const String createDisponibilities = '/web/1.0/disponibilities';

  // ── Pricing / Promo ────────────────────────────────────────────────────
  static const String customerPricing = '/web/1.0/customer/pricing';
  static const String checkPromoCode = '/web/1.0/checkpromocode';

  // ── History / Reviews ──────────────────────────────────────────────────
  static const String customerHistory = '/web/1.0/customer/history';
  static const String professionalHistory = '/web/1.0/professional/history';
  static const String customerReviews = '/web/1.0/customer/reviews';
  static const String professionalReviews = '/web/1.0/professional/reviews';
  static const String postReview = '/web/1.0/review';

  // ── Video / Session ────────────────────────────────────────────────────
  static String videoAccessToken(String seId, String coId) =>
      '/web/1.0/video/$seId/$coId/accesstoken';
  static String videoHeartbeat(String seId) => '/web/1.0/video/heartbeat/$seId';

  // ── Chat ───────────────────────────────────────────────────────────────
  static const String chatGroups = '/api/1.0/chat/groups';
  static String chatMessages(String chgrId) => '/api/1.0/chat/messages/$chgrId';
  static const String sendChatMessage = '/api/1.0/chat/message';
  static String chatImage(String chmeId) => '/api/1.0/chat/image/$chmeId';

  // ── Appointments ───────────────────────────────────────────────────────
  static const String registration = '/web/1.0/registration';
}
