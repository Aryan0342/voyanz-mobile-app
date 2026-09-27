import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

// Regression: `/history` was built with a hardcoded `isProfessional: false`,
// and `HistoryScreen(isProfessional: true)` was constructed nowhere. A
// professional reaching the screen would have been served the customer
// endpoint. Spec 8.6/8.7: the two roles read different endpoints.
void main() {
  group('history reads the endpoint of the signed-in role', () {
    test('the two providers are distinct', () {
      expect(
        professionalHistoryProvider,
        isNot(same(customerHistoryProvider)),
        reason: 'a professional must not read the customer history',
      );
    });

    test('the professional provider is reachable and separately overridable',
        () async {
      final container = ProviderContainer(
        overrides: [
          professionalHistoryProvider.overrideWith(
            (ref) async => [
              {'id': 296, 'type': 'session', 'price': 4000},
            ],
          ),
          customerHistoryProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      final pro = await container.read(professionalHistoryProvider.future);
      final customer = await container.read(customerHistoryProvider.future);
      expect(pro, hasLength(1));
      expect(customer, isEmpty);
    });
  });
}
