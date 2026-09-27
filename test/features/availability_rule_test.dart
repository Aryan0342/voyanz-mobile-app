import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/widgets/availability_rule_dialog.dart';

// Contract §10.4. The app previously sent a fixed shape — always available,
// always weekly, always every channel, one weekday, over a date window the
// professional never chose — so none of these options were reachable.
void main() {
  AvailabilityRule rule({
    bool include = true,
    String what = 'days',
    List<int> days = const [1],
    List<String> how = const ['period'],
    String from = '2026-10-01',
    String to = '2026-10-31',
    String hourFrom = '09:00',
    String hourTo = '18:00',
  }) => AvailabilityRule(
    include: include,
    what: what,
    days: days,
    how: how,
    dateFrom: from,
    dateTo: to,
    hourFrom: hourFrom,
    hourTo: hourTo,
  );

  group('AvailabilityRule.toPayload', () {
    test('sends a weekly rule with every field the spec requires', () {
      final payload = rule(days: [1, 3, 5]).toPayload();
      expect(payload['di_include'], isTrue);
      expect(payload['di_what'], 'days');
      expect(payload['di_days'], [1, 3, 5]);
      expect(payload['di_how'], ['period']);
      expect(payload['di_date_from'], '2026-10-01');
      expect(payload['di_date_to'], '2026-10-31');
      expect(payload['di_hour_from'], '09:00');
      expect(payload['di_hour_to'], '18:00');
    });

    test('carries an unavailability rule', () {
      expect(rule(include: false).toPayload()['di_include'], isFalse);
    });

    test('a single date drops di_days and mirrors the end date', () {
      final payload = rule(what: 'date', from: '2026-12-24').toPayload();
      expect(payload.containsKey('di_days'), isFalse);
      expect(payload['di_date_from'], '2026-12-24');
      // The server would set this itself; sending it keeps the body valid.
      expect(payload['di_date_to'], '2026-12-24');
    });

    test('a period rule keeps both dates and its weekdays', () {
      final payload = rule(what: 'dates', days: [6, 7]).toPayload();
      expect(payload['di_what'], 'dates');
      expect(payload['di_days'], [6, 7]);
      expect(payload['di_date_to'], '2026-10-31');
    });

    test('a single session type is sent on its own', () {
      expect(rule(how: ['phone']).toPayload()['di_how'], ['phone']);
      expect(rule(how: ['chat', 'video']).toPayload()['di_how'], [
        'chat',
        'video',
      ]);
    });

    test('ISO weekdays are what the spec asks for', () {
      // 1 = Monday ... 7 = Sunday.
      final payload = rule(days: [7]).toPayload();
      expect(payload['di_days'], [7]);
    });
  });
}
