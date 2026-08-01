import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/l10n/app_translations.dart';

/// Holds the currently selected locale code: 'fr' or 'en'.
/// Defaults to the device locale: French devices get 'fr',
/// everything else gets 'en'.
final languageProvider = StateProvider<String>((ref) {
  final deviceLang = PlatformDispatcher.instance.locale.languageCode;
  return deviceLang == 'fr' ? 'fr' : 'en';
});

/// Convenience provider that turns the language code into an [AppTranslations].
final translationsProvider = Provider<AppTranslations>((ref) {
  return AppTranslations(ref.watch(languageProvider));
});
