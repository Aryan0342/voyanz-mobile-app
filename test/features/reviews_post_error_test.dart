import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/reviews/data/reviews_history_data_source.dart';

/// Answers every request with a fixed status and JSON body (or a network
/// failure when [status] is null).
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body);
  final int? status;
  final Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (status == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(jsonEncode(body), status!, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

ReviewsHistoryDataSource _source(int? status, Object? body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://voyanz.test'))
    ..httpClientAdapter = _StubAdapter(status, body);
  return ReviewsHistoryDataSource(dio);
}

Future<ReviewSubmitException> _failure(ReviewsHistoryDataSource ds) async {
  try {
    await ds.postReview({'co_id_professional': '52', 'rv_note': 5});
  } on ReviewSubmitException catch (e) {
    return e;
  }
  fail('postReview should have thrown ReviewSubmitException');
}

void main() {
  const noSession =
      'vous devez avoir effectué au moins une séance avec ce professionnel';

  group('POST /web/1.0/review errors (API_REST §11.1, Amaury #17)', () {
    test('403 no_session surfaces the server sentence', () async {
      final e = await _failure(
        _source(403, {'error': 'no_session', 'message': noSession}),
      );
      expect(e.serverMessage, noSession);
    });

    test('403 max_reviews_reached in err{} surfaces err.message', () async {
      final e = await _failure(_source(403, {
        'err': {
          'key': 'max_reviews_reached',
          'message': 'Vous avez déjà laissé un avis pour chaque séance.',
        },
      }));
      expect(e.serverMessage, 'Vous avez déjà laissé un avis pour chaque séance.');
    });

    test('a bare key is not shown to the user', () async {
      final e = await _failure(_source(403, {'error': 'no_session'}));
      expect(e.serverMessage, isNull);
    });

    test('an error inside a 200 body is still reported', () async {
      final e = await _failure(_source(200, {
        'err': {'key': 'x', 'message': 'Avis refusé par le serveur.'},
      }));
      expect(e.serverMessage, 'Avis refusé par le serveur.');
    });

    test('network failure falls back to the localized message', () async {
      final e = await _failure(_source(null, null));
      expect(e.serverMessage, isNull);
    });

    test('a successful post does not throw', () async {
      await _source(200, {'data': {'rv_id': 1}, 'err': null}).postReview({
        'co_id_professional': '52',
        'rv_note': 5,
      });
    });
  });
}
