import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VoyanzApp()));
    await tester.pump();
    // Verify app scaffold appears.
    expect(find.text('Voyanz'), findsOneWidget);
  });
}
