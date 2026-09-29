import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/data/professional_account_data_source.dart';
import 'package:voyanz/features/professionals/data/professional_account_repository.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';
import 'package:voyanz/features/professionals/screens/professional_cgs_gate.dart';

/// Counts acceptances. The server saw two POST /accept-cgs seven seconds
/// after a login on 2026-09-28, which is one tap too many.
class _CountingRepository extends ProfessionalAccountRepository {
  _CountingRepository() : super(_UnusedDataSource());
  int accepts = 0;

  @override
  Future<void> acceptCgs() async {
    accepts++;
    // Long enough that a second tap lands while the first is in flight.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

class _UnusedDataSource implements ProfessionalAccountDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the gate must not reach the network here');
}

void main() {
  late _CountingRepository repo;

  Future<void> pumpGate(WidgetTester tester) async {
    repo = _CountingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalAccountRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfessionalCgsGate())),
      ),
    );
    await tester.pump();
  }

  testWidgets('nothing is accepted just by showing the gate', (tester) async {
    await pumpGate(tester);
    expect(repo.accepts, 0);
  });

  testWidgets('the button does nothing until the box is ticked',
      (tester) async {
    await pumpGate(tester);
    final button = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(button);
    await tester.pump();
    expect(repo.accepts, 0);
  });

  testWidgets('two taps in one frame accept exactly once', (tester) async {
    await pumpGate(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    final button = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

    // Both taps dispatch before the rebuild that disables the button.
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.accepts, 1);
  });
}
