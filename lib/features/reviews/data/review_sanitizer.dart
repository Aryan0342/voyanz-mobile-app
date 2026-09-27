/// Strips a reviews payload down to what the UI shows.
///
/// `GET /web/1.0/professional/reviews` embeds the reviewer's **entire**
/// customer record in every received review, including `co_password` (a bcrypt
/// hash), `co_accesstoken`, `co_refreshtoken`, `co_stripe_customer_id`,
/// `co_birthday`, `co_mobile1`, `co_iban` and the address (observed
/// 2026-09-27). A professional has no business holding another user's
/// credentials, and the app has no business keeping them in memory, in a cache
/// or in a crash report.
///
/// This is a mitigation, not the fix: the server should stop sending them.
/// A whitelist is used rather than a deny-list so a field added server-side
/// later stays out by default.
library;

/// Top-level keys of a review that the app renders.
const _reviewKeys = <String>{
  'rv_id',
  'rv_note',
  'rv_text',
  'rv_ispro',
  'rv_validated',
  'co_id_customer',
  'co_id_professional',
  'se_id',
  'createdAt',
  'updatedAt',
  // Older shapes the UI still falls back to.
  're_rating',
  're_comment',
  're_date',
  'co_fullname',
  'co_name',
  'name',
};

/// All the app needs of a nested `customer` / `professional`: who they are.
const _partyKeys = <String>{
  'co_id',
  'co_fullname',
  'co_firstname',
  'co_name',
};

Map<String, dynamic> _slimParty(Map raw) {
  final out = <String, dynamic>{};
  for (final key in _partyKeys) {
    final value = raw[key];
    if (value != null) out[key] = value;
  }
  return out;
}

/// One review, reduced to displayable fields.
Map<String, dynamic> sanitizeReview(Map raw) {
  final out = <String, dynamic>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString();
    if (_reviewKeys.contains(key)) {
      out[key] = entry.value;
    } else if (key == 'customer' || key == 'professional') {
      final party = entry.value;
      if (party is Map) out[key] = _slimParty(party);
    }
  }
  return out;
}

/// A list of reviews, reduced to displayable fields. Non-map rows are dropped.
List<dynamic> sanitizeReviews(List<dynamic> raw) {
  return raw
      .whereType<Map>()
      .map(sanitizeReview)
      .toList(growable: false);
}
