/// An `err` object from the backend, keeping the machine-readable key and code
/// alongside the human message.
///
/// The message alone is not enough to branch on: the server sends prose, which
/// is translated and may be reworded, so matching on it is unreliable. Callers
/// match [key] or [code]; [toString] stays the message so anything that simply
/// shows the error is unaffected.
class ApiException implements Exception {
  final String message;
  final String? key;
  final int? code;

  const ApiException(this.message, {this.key, this.code});

  /// True when this error is the given `err.key` or `err.code`.
  bool matches(String key, [int? code]) =>
      this.key == key || (code != null && this.code == code);

  @override
  String toString() => message;
}
