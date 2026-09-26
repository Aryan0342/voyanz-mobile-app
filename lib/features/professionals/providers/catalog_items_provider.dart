import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable value of the professional profile: the server stores the
/// `li_key`, the UI shows the label (contract P1).
class CatalogItem {
  final String key;
  final String label;

  const CatalogItem({required this.key, required this.label});

  Map<String, String> toJson() => {'key': key, 'label': label};

  static CatalogItem? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final key = (raw['li_key'] ?? raw['key'] ?? raw['id'])?.toString().trim();
    if (key == null || key.isEmpty) return null;
    final label =
        (raw['li_val'] ??
                raw['li_name'] ??
                raw['label'] ??
                raw['name'] ??
                raw['value'] ??
                key)
            .toString()
            .trim();
    return CatalogItem(key: key, label: label.isEmpty ? key : label);
  }
}

/// The `items` object from `POST /api/1.0/login`: the allowed values for
/// categories, specialities and languages.
///
/// Persisted because a restored session never replays the login response.
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

  /// Accepts both shapes seen from the backend:
  /// * an object: `{ "items_tools": [...], "items_specialities": [...] }`
  /// * a flat list whose rows name their list: `[{ "li_name": "items_tools",
  ///   "li_key": "tarot", "li_val": "Tarology" }, ...]`
  factory CatalogItems.fromLogin(dynamic items) {
    if (items is Map) {
      return CatalogItems(
        tools: _parse(items['items_tools']),
        specialities: _parse(items['items_specialities']),
        languages: _parse(items['items_languages']),
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
    'items_tools': tools.map((e) => e.toJson()).toList(),
    'items_specialities': specialities.map((e) => e.toJson()).toList(),
    'items_languages': languages.map((e) => e.toJson()).toList(),
  };
}

const _prefsKey = 'catalog_items';

class CatalogItemsNotifier extends StateNotifier<CatalogItems> {
  CatalogItemsNotifier() : super(const CatalogItems()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        state = CatalogItems.fromLogin(decoded);
      }
    } catch (_) {}
  }

  /// Keeps the last non-empty `items` payload seen at login.
  Future<void> save(CatalogItems items) async {
    if (items.isEmpty) return;
    state = items;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(items.toJson()));
    } catch (_) {}
  }
}

final catalogItemsProvider =
    StateNotifierProvider<CatalogItemsNotifier, CatalogItems>((ref) {
      return CatalogItemsNotifier();
    });
