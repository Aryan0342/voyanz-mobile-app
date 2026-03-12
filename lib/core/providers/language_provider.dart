import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/l10n/app_translations.dart';

/// Holds the currently selected locale code: 'fr' (default) or 'en'.
final languageProvider = StateProvider<String>((ref) => 'fr');

/// Convenience provider that turns the language code into an [AppTranslations].
final translationsProvider = Provider<AppTranslations>((ref) {
  return AppTranslations(ref.watch(languageProvider));
});
