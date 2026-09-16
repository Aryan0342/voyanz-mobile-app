import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voyanz/core/l10n/app_translations.dart';

const _languagePreferenceKey = 'app_language';

String _deviceLanguage() {
  final deviceLang = PlatformDispatcher.instance.locale.languageCode;
  return switch (deviceLang) {
    'fr' => 'fr',
    'es' => 'es',
    _ => 'en',
  };
}

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_deviceLanguage()) {
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_languagePreferenceKey);
    if (savedLanguage == 'fr' ||
        savedLanguage == 'en' ||
        savedLanguage == 'es') {
      state = savedLanguage!;
    }
  }

  Future<void> selectLanguage(String language) async {
    if (language != 'fr' && language != 'en' && language != 'es') return;
    state = language;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languagePreferenceKey, language);
  }
}

/// Holds and persists the currently selected locale code: 'fr', 'en' or 'es'.
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

/// Convenience provider that turns the language code into an [AppTranslations].
final translationsProvider = Provider<AppTranslations>((ref) {
  return AppTranslations(ref.watch(languageProvider));
});
