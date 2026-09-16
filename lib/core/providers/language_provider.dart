import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/l10n/app_translations.dart';

/// Holds the currently selected locale code: 'fr', 'en' or 'es'.
final languageProvider = StateProvider<String>((ref) {
  final deviceLang = PlatformDispatcher.instance.locale.languageCode;
  return switch (deviceLang) {
    'fr' => 'fr',
    'es' => 'es',
    _ => 'en',
  };
});

/// Convenience provider that turns the language code into an [AppTranslations].
final translationsProvider = Provider<AppTranslations>((ref) {
  return AppTranslations(ref.watch(languageProvider));
});
