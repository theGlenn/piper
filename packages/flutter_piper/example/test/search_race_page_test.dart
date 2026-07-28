import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the search race shows cancellation before fresh results', (
    tester,
  ) async {
    await tester.pumpWidget(const PiperSearchRaceApp());

    expect(find.text('The slow request should lose.'), findsOneWidget);
    expect(find.text('Run search race'), findsOneWidget);

    await tester.tap(find.text('Run search race'));
    await tester.pump(const Duration(milliseconds: 230));
    await tester.pump(const Duration(milliseconds: 290));

    expect(find.text('Task for “f” cancelled'), findsOneWidget);
    expect(find.text('Results for “flutter” committed'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('1 stale request prevented'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1200));
  });
}
