import 'package:flutter_test/flutter_test.dart';

// Mirrors _extractHowValues in professional_availability_screen.dart.
// di_how channels combine; ['period'] and [] both mean every session type.
// Two legacy rows store an object {"chat": true, "audio": true, ...}.
List<String> extractHowValues(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (raw is Map) {
    return raw.entries
        .where((e) => e.value == true || e.value == 1 || e.value == '1')
        .map((e) => e.key.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final text = raw?.toString().trim().toLowerCase() ?? '';
  return text.isEmpty ? const [] : [text];
}

void main() {
  group('di_how', () {
    test('channels combine', () {
      expect(extractHowValues(['phone', 'chat', 'video']),
          ['phone', 'chat', 'video']);
    });

    test('an empty list means no restriction, not a bogus channel', () {
      expect(extractHowValues([]), isEmpty);
      expect(extractHowValues(null), isEmpty);
      expect(extractHowValues(''), isEmpty);
    });

    // Without the Map branch the whole object stringifies into one channel
    // named "{chat: true, audio: true, video: true}".
    test('the legacy object form yields real channel names', () {
      final got = extractHowValues({'chat': true, 'audio': true, 'video': true});
      expect(got, containsAll(<String>['chat', 'audio', 'video']));
      expect(got.any((c) => c.contains('{')), isFalse);
    });

    test('a false channel in the legacy object is not selected', () {
      expect(extractHowValues({'chat': true, 'audio': false}), ['chat']);
    });

    test('period still means every session type', () {
      expect(extractHowValues(['period']), ['period']);
    });
  });
}
