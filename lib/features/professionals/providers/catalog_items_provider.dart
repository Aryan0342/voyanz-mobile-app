import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/core/utils/string_utils.dart';
import 'package:voyanz/features/professionals/data/catalog_data_source.dart';

/// One selectable value of the professional profile: the server stores the
/// `li_key`, the UI shows the label for the active language (contract P1c).
class CatalogItem {
  final String key;

  /// `li_val` — the server's own display value. It is French, and for several
  /// entries it is better spelled than the translation (`Voyance générale`
  /// against a `label.fr` of `Voyance_generale`), so it serves as a fallback.
  final String value;

  /// `label` — `{ fr, en, es }`.
  final Map<String, String> labels;

  const CatalogItem({
    required this.key,
    this.value = '',
    this.labels = const {},
  });

  /// The label to show in [language], working around the gaps in the
  /// translations the server returns (observed 2026-09-27): some fall through
  /// to the raw key (`Voyance_generale`, `Ligne_de_main`), some are left in
  /// French (`autres`, `travail` in English), and some lose their accents
  /// (`Reves`, `Suenos`).
  ///
  /// A label in the right language always wins, even when it arrives as a
  /// slug: a Spanish professional is better served by "Videncia general" than
  /// by the English "General clairvoyance". `li_val` is the server's French
  /// value and is properly accented, so French prefers it over a French slug.
  String labelFor(String language) {
    final own = labels[language]?.trim() ?? '';
    if (_isUsable(own)) return own;

    final frenchValue = value.trim();
    if (language == 'fr' && _isUsable(frenchValue)) return frenchValue;

    if (own.isNotEmpty) return _deslug(own);

    final english = labels['en']?.trim() ?? '';
    if (_isUsable(english)) return english;
    if (_isUsable(frenchValue)) return frenchValue;

    for (final candidate in [own, english, frenchValue, key]) {
      if (candidate.trim().isNotEmpty) return _deslug(candidate);
    }
    return key;
  }

  /// Removes the underscores of a key that reached the UI as a label, without
  /// recapitalising the words that follow -- "Videncia general", not
  /// "Videncia General".
  static String _deslug(String raw) {
    final text = raw.trim().replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static bool _isUsable(String? text) {
    final value = text?.trim() ?? '';
    // An underscore means the translation fell through to the raw key.
    return value.isNotEmpty && !value.contains('_');
  }

  Map<String, dynamic> toJson() => {
    'li_key': key,
    'li_val': value,
    'label': labels,
  };

  static CatalogItem? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final key = (raw['li_key'] ?? raw['key'] ?? raw['id'])?.toString().trim();
    if (key == null || key.isEmpty) return null;

    final labels = <String, String>{};
    final rawLabels = raw['label'] ?? raw['labels'];
    if (rawLabels is Map) {
      rawLabels.forEach((language, text) {
        final code = language?.toString().trim().toLowerCase() ?? '';
        final label = text?.toString().trim() ?? '';
        if (code.isNotEmpty && label.isNotEmpty) labels[code] = label;
      });
    }

    final value =
        (raw['li_val'] ?? raw['li_name'] ?? raw['value'] ?? raw['name'] ?? '')
            .toString()
            .trim();

    return CatalogItem(key: key, value: value, labels: labels);
  }
}

/// The allowed values for a professional's categories, specialities and
/// languages (contract P1c).
///
/// Persisted because the app must offer them to a restored session too, and
/// `GET /web/1.0/items` cannot be reached while offline.
class CatalogItems {
  final List<CatalogItem> tools;
  final List<CatalogItem> specialities;
  final List<CatalogItem> languages;

  const CatalogItems({
    this.tools = const [],
    this.specialities = const [],
    this.languages = const [],
  });

  bool get isEmpty =>
      tools.isEmpty && specialities.isEmpty && languages.isEmpty;

  static List<CatalogItem> _parse(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(CatalogItem.fromJson)
        .whereType<CatalogItem>()
        .toList(growable: false);
  }

  /// `GET /web/1.0/items` — `{ data: { tools, specialities, languages } }`.
  factory CatalogItems.fromItemsEndpoint(dynamic body) {
    final root = body is Map && body['data'] is Map ? body['data'] : body;
    if (root is! Map) return const CatalogItems();
    return CatalogItems(
      tools: _parse(root['tools'] ?? root['items_tools']),
      specialities: _parse(root['specialities'] ?? root['items_specialities']),
      languages: _parse(root['languages'] ?? root['items_languages']),
    );
  }

  /// The `items` object on the login response, which uses the prefixed names.
  ///
  /// Kept as a secondary source: `GET /web/1.0/items` is the one to rely on,
  /// but when login does carry the payload there is no reason to ignore it.
  /// A flat list whose rows name their own list is accepted too.
  factory CatalogItems.fromLogin(dynamic items) {
    if (items is Map) {
      return CatalogItems(
        tools: _parse(items['items_tools'] ?? items['tools']),
        specialities: _parse(
          items['items_specialities'] ?? items['specialities'],
        ),
        languages: _parse(items['items_languages'] ?? items['languages']),
      );
    }
    if (items is List) {
      final grouped = <String, List<dynamic>>{};
      for (final row in items) {
        if (row is! Map) continue;
        final listName = (row['li_name'] ?? row['list'] ?? row['type'])
            ?.toString();
        if (listName == null || listName.isEmpty) continue;
        grouped.putIfAbsent(listName, () => <dynamic>[]).add(row);
      }
      return CatalogItems(
        tools: _parse(grouped['items_tools']),
        specialities: _parse(grouped['items_specialities']),
        languages: _parse(grouped['items_languages']),
      );
    }
    return const CatalogItems();
  }

  Map<String, dynamic> toJson() => {
    'tools': tools.map((e) => e.toJson()).toList(),
    'specialities': specialities.map((e) => e.toJson()).toList(),
    'languages': languages.map((e) => e.toJson()).toList(),
  };
}

const _prefsKey = 'catalog_items';

class CatalogItemsNotifier extends StateNotifier<CatalogItems> {
  CatalogItemsNotifier(this._source) : super(const CatalogItems()) {
    _restore();
  }

  final CatalogDataSource _source;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      final restored = CatalogItems.fromItemsEndpoint(decoded);
      // Never overwrite a fresher list fetched while this was reading.
      if (!restored.isEmpty && state.isEmpty) state = restored;
    } catch (_) {}
  }

  /// Fetches the catalogue. Called at sign-in and on session restore, since a
  /// restored session never replays the login response (contract P1c).
  Future<void> refresh() async {
    try {
      await save(await _source.getItems());
    } catch (_) {
      // An unreachable catalogue must not break signing in: the cached copy
      // stays usable and the editor explains itself when there is none.
    }
  }

  /// Keeps the last non-empty payload.
  Future<void> save(CatalogItems items) async {
    if (items.isEmpty) return;
    state = items;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(items.toJson()));
    } catch (_) {}
  }
}

final catalogDataSourceProvider = Provider<CatalogDataSource>((ref) {
  return CatalogDataSource(ref.watch(dioProvider));
});

final catalogItemsProvider =
    StateNotifierProvider<CatalogItemsNotifier, CatalogItems>((ref) {
      return CatalogItemsNotifier(ref.watch(catalogDataSourceProvider));
    });
