import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/providers/catalog_items_provider.dart';

/// Captured from `GET /web/1.0/items` on voyanz.com, 2026-09-27.
const _liveBody = {
  'data': {
    'tools': [
      {
        'li_key': 'tarologie',
        'li_val': 'Tarologie',
        'label': {'fr': 'Tarologie', 'en': 'Tarology', 'es': 'Tarot'},
      },
      {
        'li_key': 'reves',
        'li_val': 'Rêves',
        'label': {'fr': 'Reves', 'en': 'Dreams', 'es': 'Suenos'},
      },
      {
        'li_key': 'ligne_de_main',
        'li_val': 'Ligne de main',
        'label': {
          'fr': 'Ligne_de_main',
          'en': 'Ligne_de_main',
          'es': 'Linea_de_mano',
        },
      },
    ],
    'specialities': [
      {
        'li_key': 'voyance_generale',
        'li_val': 'Voyance générale',
        'label': {
          'fr': 'Voyance_generale',
          'en': 'General clairvoyance',
          'es': 'Videncia_general',
        },
      },
      {
        'li_key': 'amour',
        'li_val': 'Amour',
        'label': {'fr': 'Amour', 'en': 'Love', 'es': 'Amor'},
      },
    ],
    'languages': [
      {
        'li_key': 'fr',
        'li_val': 'Français',
        'label': {'fr': 'Français', 'en': 'French', 'es': 'Francés'},
      },
      {
        'li_key': 'de',
        'li_val': 'Allemand',
        'label': {'fr': 'De', 'en': 'From', 'es': 'De'},
      },
    ],
  },
  'err': null,
  'meta': {},
};

void main() {
  group('CatalogItems.fromItemsEndpoint', () {
    test('reads the three lists out of the data envelope', () {
      final items = CatalogItems.fromItemsEndpoint(_liveBody);
      expect(items.tools.length, 3);
      expect(items.specialities.length, 2);
      expect(items.languages.length, 2);
      expect(items.isEmpty, isFalse);
    });

    test('keeps li_key as the value sent back on save', () {
      final items = CatalogItems.fromItemsEndpoint(_liveBody);
      expect(items.tools.first.key, 'tarologie');
      expect(items.specialities.map((e) => e.key), ['voyance_generale', 'amour']);
    });

    test('accepts a body without the data envelope', () {
      final items = CatalogItems.fromItemsEndpoint(_liveBody['data']);
      expect(items.tools.length, 3);
    });

    test('an error body yields an empty catalogue rather than throwing', () {
      expect(CatalogItems.fromItemsEndpoint(null).isEmpty, isTrue);
      expect(CatalogItems.fromItemsEndpoint('nonsense').isEmpty, isTrue);
      expect(CatalogItems.fromItemsEndpoint(const {}).isEmpty, isTrue);
    });
  });

  group('CatalogItem.labelFor', () {
    CatalogItem toolNamed(String key) => CatalogItems.fromItemsEndpoint(
      _liveBody,
    ).tools.firstWhere((e) => e.key == key);

    test('shows the label of the active language', () {
      final tarot = toolNamed('tarologie');
      expect(tarot.labelFor('fr'), 'Tarologie');
      expect(tarot.labelFor('en'), 'Tarology');
      expect(tarot.labelFor('es'), 'Tarot');
    });

    // The server's translations have gaps; none may reach the UI as a raw
    // slug, because the professional would see `Voyance_generale`.
    test('never shows an underscore', () {
      final items = CatalogItems.fromItemsEndpoint(_liveBody);
      for (final item in [
        ...items.tools,
        ...items.specialities,
        ...items.languages,
      ]) {
        for (final language in ['fr', 'en', 'es']) {
          expect(
            item.labelFor(language),
            isNot(contains('_')),
            reason: '${item.key} in $language',
          );
        }
      }
    });

    // A slug in the right language beats a correct word in the wrong one: a
    // Spanish professional reading "General clairvoyance" is worse served
    // than by "Videncia general".
    test('prefers its own language over English when the label is a slug', () {
      final general = CatalogItems.fromItemsEndpoint(
        _liveBody,
      ).specialities.firstWhere((e) => e.key == 'voyance_generale');
      expect(general.labelFor('es'), 'Videncia general');
      expect(general.labelFor('en'), 'General clairvoyance');
    });

    // `li_val` is the server's French value and keeps its accents, so French
    // takes it over its own de-slugged label.
    test('French prefers li_val over a French slug', () {
      final general = CatalogItems.fromItemsEndpoint(
        _liveBody,
      ).specialities.firstWhere((e) => e.key == 'voyance_generale');
      expect(general.labelFor('fr'), 'Voyance générale');

      final palm = toolNamed('ligne_de_main');
      expect(palm.labelFor('fr'), 'Ligne de main');
    });

    test('de-slugging does not recapitalise every word', () {
      final palm = toolNamed('ligne_de_main');
      expect(palm.labelFor('es'), 'Linea de mano');
    });

    test('never returns an empty label', () {
      const bare = CatalogItem(key: 'mystery');
      expect(bare.labelFor('fr'), isNotEmpty);
      expect(bare.labelFor('fr'), 'Mystery');
    });

    test('a missing language falls back rather than blanking the chip', () {
      const item = CatalogItem(
        key: 'pendule',
        value: 'Pendule',
        labels: {'en': 'Pendulum'},
      );
      expect(item.labelFor('es'), 'Pendulum');
    });
  });

  group('CatalogItems.fromLogin', () {
    test('reads the prefixed names of the login payload', () {
      final items = CatalogItems.fromLogin({
        'items_tools': [
          {'li_key': 'runes', 'li_val': 'Runes'},
        ],
        'items_specialities': [
          {'li_key': 'amour', 'li_val': 'Amour'},
        ],
        'items_languages': [
          {'li_key': 'fr', 'li_val': 'Français'},
        ],
      });
      expect(items.tools.single.key, 'runes');
      expect(items.specialities.single.key, 'amour');
      expect(items.languages.single.key, 'fr');
    });

    test('a flat list is grouped by the list it names', () {
      final items = CatalogItems.fromLogin([
        {'li_name': 'items_tools', 'li_key': 'runes', 'li_val': 'Runes'},
        {'li_name': 'items_languages', 'li_key': 'fr', 'li_val': 'Français'},
      ]);
      expect(items.tools.single.key, 'runes');
      expect(items.languages.single.key, 'fr');
    });

    test('a missing payload is empty, not an error', () {
      // The live server returned no `items` at all before P1c.
      expect(CatalogItems.fromLogin(null).isEmpty, isTrue);
    });
  });

  group('round trip through the cache', () {
    test('survives being stored and restored', () {
      final original = CatalogItems.fromItemsEndpoint(_liveBody);
      final restored = CatalogItems.fromItemsEndpoint(original.toJson());
      expect(restored.tools.length, original.tools.length);
      expect(restored.languages.map((e) => e.key), ['fr', 'de']);
      expect(restored.tools.first.labelFor('es'), 'Tarot');
    });
  });
}
