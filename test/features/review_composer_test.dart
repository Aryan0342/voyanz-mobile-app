import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/features/professionals/models/professional.dart';
import 'package:voyanz/features/reviews/widgets/review_composer.dart';

// Amaury #18 / #19: the composer must be fully translated and must not show
// the backend co_type ("professional") under the name.
Future<void> _openComposer(WidgetTester tester, String lang) async {
  const pro = Professional(coId: '52', firstName: 'Rachelle');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        translationsProvider.overrideWithValue(AppTranslations(lang)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showReviewComposer(context, ref, pro),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('French composer: stars in French, no co_type subtitle', (
    tester,
  ) async {
    await _openComposer(tester, 'fr');

    expect(find.text('Rachelle'), findsOneWidget);
    expect(find.textContaining('rofessional'), findsNothing);
    expect(find.text('5 étoiles'), findsOneWidget);

    await tester.tap(find.text('5 étoiles'));
    await tester.pumpAndSettle();
    expect(find.text('1 étoile').hitTestable(), findsOneWidget);
    expect(find.textContaining('star'), findsNothing);
  });

  testWidgets('Spanish composer uses estrellas', (tester) async {
    await _openComposer(tester, 'es');
    expect(find.text('5 estrellas'), findsOneWidget);
    expect(find.textContaining('star'), findsNothing);
    expect(find.textContaining('rofessional'), findsNothing);
  });
}
