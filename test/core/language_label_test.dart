import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/l10n/app_translations.dart';

void main() {
  // `co_languages` holds bare ISO 639-1 codes, so anything that renders them
  // straight shows "fr" to the customer. Observed live values: fr, en, ar.
  group('languageLabel', () {
    test('names the three app languages in each language', () {
      expect(AppTranslations('en').languageLabel('fr'), 'French');
      expect(AppTranslations('fr').languageLabel('fr'), 'Français');
      expect(AppTranslations('es').languageLabel('fr'), 'Francés');
    });

    test('names a language the app itself is not translated into', () {
      expect(AppTranslations('en').languageLabel('ar'), 'Arabic');
      expect(AppTranslations('fr').languageLabel('ar'), 'Arabe');
      expect(AppTranslations('es').languageLabel('ar'), 'Árabe');
    });

    test('ignores case and surrounding whitespace', () {
      expect(AppTranslations('en').languageLabel(' FR '), 'French');
      expect(AppTranslations('en').languageLabel('En'), 'English');
    });

    test('an unknown code is capitalised rather than dropped', () {
      // A professional really does speak it, so it must stay visible.
      expect(AppTranslations('en').languageLabel('sw'), 'Sw');
      expect(AppTranslations('en').languageLabel(''), '');
    });

    test('never leaves a bare lowercase code for a known language', () {
      for (final lang in ['fr', 'en', 'es']) {
        final t = AppTranslations(lang);
        for (final code in ['fr', 'en', 'es', 'ar', 'de', 'it', 'pt']) {
          expect(t.languageLabel(code), isNot(code));
        }
      }
    });
  });
}
