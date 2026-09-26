import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/providers/catalog_items_provider.dart';

// The login response's `items` is documented as an array but described by the
// backend as an object, so the app accepts either.
void main() {
  group('CatalogItems.fromLogin', () {
    test('object shape', () {
      final items = CatalogItems.fromLogin({
        'items_tools': [
          {'li_key': 'tarot', 'li_val': 'Tarology'},
        ],
        'items_specialities': [
          {'li_key': 'love', 'li_val': 'Love'},
        ],
        'items_languages': [
          {'li_key': 'fr', 'li_val': 'French'},
        ],
      });
      expect(items.tools.single.key, 'tarot');
      expect(items.tools.single.label, 'Tarology');
      expect(items.specialities.single.key, 'love');
      expect(items.languages.single.label, 'French');
    });

    test('flat list shape grouped by li_name', () {
      final items = CatalogItems.fromLogin([
        {'li_name': 'items_tools', 'li_key': 'runes', 'li_val': 'Runes'},
        {'li_name': 'items_tools', 'li_key': 'pendulum', 'li_val': 'Pendulum'},
        {'li_name': 'items_specialities', 'li_key': 'finance', 'li_val': 'Finance'},
      ]);
      expect(items.tools.map((e) => e.key), ['runes', 'pendulum']);
      expect(items.specialities.single.key, 'finance');
      expect(items.languages, isEmpty);
    });

    test('empty, null and unexpected shapes are harmless', () {
      expect(CatalogItems.fromLogin(null).isEmpty, isTrue);
      expect(CatalogItems.fromLogin(const []).isEmpty, isTrue);
      expect(CatalogItems.fromLogin('nonsense').isEmpty, isTrue);
    });

    test('falls back to the key when no label is sent', () {
      final items = CatalogItems.fromLogin({
        'items_tools': [
          {'li_key': 'runes'},
        ],
      });
      expect(items.tools.single.label, 'runes');
    });
  });
}
