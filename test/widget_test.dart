import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/main.dart';

void main() {
  Future<void> openCalculator(WidgetTester tester) async {
    await tester.pumpWidget(const CandleApp());
    await tester.tap(find.byKey(const Key('welcome-screen')));
    await tester.pumpAndSettle();
  }

  String value(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('welcome opens with $key', (tester) async {
      await tester.pumpWidget(const CandleApp());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wax-weight')), findsOneWidget);
    });
  }

  testWidgets('calculator fits a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openCalculator(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('split-button')));
    await tester.tap(find.byKey(const Key('split-button')));
    await tester.pumpAndSettle();
  });

  testWidgets('updates batch and split amounts as inputs change', (
    tester,
  ) async {
    await openCalculator(tester);
    expect(value(tester, 'fragrance-per-container'), '—');
    await tester.enterText(find.byKey(const Key('wax-weight')), '100');
    await tester.enterText(find.byKey(const Key('container-count')), '5');
    await tester.pumpAndSettle();

    expect(value(tester, 'fragrance-per-container'), '8.00 g');
    expect(value(tester, 'total-wax'), '500.00 g');
    expect(value(tester, 'total-fragrance'), '40.00 g');

    await tester.ensureVisible(find.byKey(const Key('split-button')));
    await tester.tap(find.byKey(const Key('split-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('fragrance-count')));
    await tester.tap(find.byKey(const Key('fragrance-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 fragrances').last);
    await tester.pumpAndSettle();
    expect(value(tester, 'split-per-container'), '4.00 g');
    expect(value(tester, 'split-per-batch'), '20.00 g');

    await tester.tap(find.byKey(const Key('fragrance-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 fragrances').last);
    await tester.pumpAndSettle();
    expect(value(tester, 'split-per-container'), '2.67 g');
    expect(value(tester, 'split-per-batch'), '13.33 g');
  });

  testWidgets('invalid entries clear affected results', (tester) async {
    await openCalculator(tester);
    await tester.enterText(find.byKey(const Key('wax-weight')), '100');
    await tester.enterText(find.byKey(const Key('container-count')), '0');
    await tester.pumpAndSettle();
    expect(value(tester, 'fragrance-per-container'), '8.00 g');
    expect(value(tester, 'total-wax'), '—');
    expect(
      find.text('Enter a positive whole number of containers.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('wax-weight')), '-2');
    await tester.pumpAndSettle();
    expect(value(tester, 'fragrance-per-container'), '—');
    expect(value(tester, 'total-fragrance'), '—');
    expect(find.text('Enter a wax weight greater than zero.'), findsOneWidget);
  });
}
