/// One entry of `mycustomers` from `GET /web/1.0/professional/reviews`: the
/// clients a professional may review (contract §11.1, `rv_ispro`).
///
/// The server sends `{ "key": 184, "value": "Shahzeb QA" }` and puts a
/// placeholder row first (`key: 0`, "Choisir un client" — hardcoded French),
/// which is dropped here so the app can label the empty choice itself.
class ReviewClient {
  final String id;
  final String name;

  const ReviewClient({required this.id, required this.name});

  static ReviewClient? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = (raw['key'] ?? raw['co_id'] ?? raw['id'])?.toString().trim();
    if (id == null || id.isEmpty || id == '0') return null;
    final name = (raw['value'] ?? raw['co_fullname'] ?? raw['name'] ?? '')
        .toString()
        .trim();
    return ReviewClient(id: id, name: name.isEmpty ? id : name);
  }

  /// Reads the client list out of the professional reviews payload.
  static List<ReviewClient> listFrom(dynamic body) {
    final root = body is Map && body['data'] is Map ? body['data'] : body;
    if (root is! Map) return const [];
    final raw = root['mycustomers'] ?? root['customers'];
    if (raw is! List) return const [];
    return raw
        .map(ReviewClient.fromJson)
        .whereType<ReviewClient>()
        .toList(growable: false);
  }
}
