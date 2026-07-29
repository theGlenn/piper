import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The race types “flutter” over 6 × 90ms intervals, so the fast search
  // starts at ~540ms and resolves at ~820ms; the slow “f” search resolves
  // at 1200ms.
  Future<void> runRaceUntilFastResult(WidgetTester tester) async {
    await tester.tap(find.text('Run search race'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('without Piper the late response overwrites fresh results', (
    tester,
  ) async {
    await tester.pumpWidget(const PiperSearchRaceApp());

    expect(
      find.text('You typed “flutter”. The “f” response arrives last.'),
      findsOneWidget,
    );
    expect(find.text('Without Piper'), findsOneWidget);

    await runRaceUntilFastResult(tester);
    expect(find.text('Flutter'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Firebase'), findsOneWidget);
    expect(find.text('Flutter'), findsNothing);
    expect(find.text('STALE'), findsOneWidget);
    expect(
      find.text('Late “f” response arrived — overwrote the newer results'),
      findsOneWidget,
    );
  });

  testWidgets('with Piper the cancelled response cannot land', (tester) async {
    await tester.pumpWidget(const PiperSearchRaceApp());

    await tester.tap(find.text('With Piper'));
    await tester.pump();

    await runRaceUntilFastResult(tester);
    expect(
      find.text('Task for “f” cancelled — its response will be ignored'),
      findsOneWidget,
    );
    expect(find.text('Results for “flutter” shown'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Firebase'), findsNothing);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('STALE'), findsNothing);
    expect(find.text('Late “f” response arrived — discarded'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1300));
  });
}
