import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/network/account_requirement_interceptor.dart';

void main() {
  group('AccountRequirement.fromKeyOrCode', () {
    test('recognises the CGS refusal by key and by code', () {
      expect(
        AccountRequirement.fromKeyOrCode('cgs_acceptance_required', null),
        AccountRequirement.cgsAcceptance,
      );
      expect(
        AccountRequirement.fromKeyOrCode(null, 1073),
        AccountRequirement.cgsAcceptance,
      );
    });

    test('recognises the verification refusals', () {
      expect(
        AccountRequirement.fromKeyOrCode('email_not_verified', null),
        AccountRequirement.emailNotVerified,
      );
      expect(
        AccountRequirement.fromKeyOrCode(null, 1031),
        AccountRequirement.smsNotVerified,
      );
    });

    test('an unrelated error is not a requirement', () {
      expect(AccountRequirement.fromKeyOrCode('wrong_password', 1004), isNull);
      expect(AccountRequirement.fromKeyOrCode(null, null), isNull);
    });
  });

  // The interceptor is what opens the gate: the profile's own `cgs_accepted`
  // was observed still reporting `true` while the account was gated
  // (2026-09-27), so the refusal must be the trigger.
  group('AccountRequirementInterceptor', () {
    late List<AccountRequirement> seen;

    setUp(() {
      seen = [];
      AccountRequirementInterceptor.onRequirement = (r, _) => seen.add(r);
    });

    tearDown(() => AccountRequirementInterceptor.onRequirement = null);

    Response<dynamic> responseWith(dynamic body) => Response(
      requestOptions: RequestOptions(path: '/web/1.0/professional/profile'),
      data: body,
      statusCode: 200,
    );

    test('reports a refusal delivered as a 200 body', () {
      AccountRequirementInterceptor().onResponse(
        responseWith({
          'err': {'key': 'cgs_acceptance_required', 'code': 1073},
        }),
        ResponseInterceptorHandler(),
      );
      expect(seen, [AccountRequirement.cgsAcceptance]);
    });

    test('reports a refusal delivered as an error', () {
      // Passing the error along rejects the handler's future by design; the
      // rejection is the transport's business, the callback is ours.
      runZonedGuarded(() {
        AccountRequirementInterceptor().onError(
          DioException(
            requestOptions: RequestOptions(path: '/web/1.0/balance'),
            response: responseWith({
              'err': {'key': 'cgs_acceptance_required', 'code': 1073},
            }),
          ),
          ErrorInterceptorHandler(),
        );
      }, (_, __) {});
      expect(seen, [AccountRequirement.cgsAcceptance]);
    });

    test('stays silent on a healthy response', () {
      AccountRequirementInterceptor().onResponse(
        responseWith({
          'data': {'cgs_accepted': true},
          'err': null,
        }),
        ResponseInterceptorHandler(),
      );
      expect(seen, isEmpty);
    });
  });
}
