/// Central registry of every REST endpoint the mobile app consumes.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = '/api/1.0/login';
  static const String forgetPassword = '/api/1.0/forgetpassword';
  static const String userInfos = '/web/1.0/user/infos';

  // ── Account ────────────────────────────────────────────────────────────
  static const String createAccount = '/web/1.0/account';
  static String updateAccount(String coId) => '/web/1.0/account/$coId';
  static String updateProDescription(String coId) =>
      '/web/1.0/account/description/$coId';
  /// DELETE: anonymises a customer immediately; for a professional it opens a
  /// deletion request and logs them out (contract P4).
  static String deleteAccount(String coId) => '/web/1.0/account/$coId';
  static String accountImage(String coId) => '/web/1.0/account/$coId/image';

  // ── Professionals ──────────────────────────────────────────────────────
  static const String professionals = '/web/1.0/professionals';
  static String professionalInfos(String coId) =>
      '/web/1.0/professional/$coId/infos';
  static const String professionalAccount = '/web/1.0/professional/account';
  /// Everything the professional edit screen needs, readable before
  /// activation and before CGS acceptance (contract P1).
  static const String professionalProfile = '/web/1.0/professional/profile';
  static const String acceptCgs = '/web/1.0/professional/accept-cgs';
  static String professionalFavorite(String coId) =>
      '/web/1.0/professional/favorite/$coId';
  static const String professionalDisponibilities =
      '/web/1.0/professional/disponibilities';
  static const String createDisponibilities = '/web/1.0/disponibilities';
  static String updateDisponibility(String diId) =>
      '/web/1.0/disponibilities/$diId';
  static String deleteDisponibility(String diId) =>
      '/web/1.0/disponibilities/$diId';

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
  static String createSessionCall(String typeCall, String coId) =>
      '/web/1.0/call/$typeCall/$coId';
  static String sessionStatus(String seId) => '/web/1.0/session/$seId';
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
  static const String publicVideoSessions = '/web/1.0/public/video-sessions';

  // ── Catalogue (contract P1c) ─────────────────────────────────────
  /// Allowed tools, specialities and languages. Called at sign-in and on
  /// session restore, because a restored session never replays the login
  /// response that also carries them.
  static const String items = '/web/1.0/items';

  // ── Wallet / Payment ──────────────────────────────────────────────────
  static const String stripePaymentIntent = '/stripe/payment-intent';
  static const String checkBalance = '/web/1.0/check-balance';
  static String payreturnStatusById(String pi) =>
      '/web/1.0/payreturn/status/$pi';
  static const String getBalance = '/web/1.0/balance';
}
