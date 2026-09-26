import 'package:dio/dio.dart';

/// Account states the backend refuses to work around (contract P3).
///
/// Since 26 September 2026 any `/web/1.0/professional/*` call answers with
/// `{ "err": { "key": ..., "code": ... } }` instead of an HTML redirect when
/// `x-api-key` is sent, so the app can react instead of failing silently.
enum AccountRequirement {
  cgsAcceptance('cgs_acceptance_required', 1073),
  emailNotVerified('email_not_verified', 1030),
  smsNotVerified('sms_not_verified', 1031);

  const AccountRequirement(this.key, this.code);

  final String key;
  final int code;

  static AccountRequirement? fromKeyOrCode(String? key, int? code) {
    for (final value in AccountRequirement.values) {
      if (key == value.key || code == value.code) return value;
    }
    return null;
  }
}

/// Watches every response for those keys and reports them once, so a
/// professional is never left looking at a screen that silently does nothing.
class AccountRequirementInterceptor extends Interceptor {
  /// Wired by the app root; receives the requirement and the server's message.
  static void Function(AccountRequirement requirement, String? message)?
  onRequirement;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _report(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _report(err.response?.data);
    handler.next(err);
  }

  void _report(dynamic body) {
    if (body is! Map) return;
    final err = body['err'];
    if (err is! Map) return;

    final key = err['key']?.toString();
    final rawCode = err['code'];
    final code = rawCode is int
        ? rawCode
        : int.tryParse(rawCode?.toString() ?? '');

    final requirement = AccountRequirement.fromKeyOrCode(key, code);
    if (requirement == null) return;

    onRequirement?.call(requirement, err['message']?.toString());
  }
}
