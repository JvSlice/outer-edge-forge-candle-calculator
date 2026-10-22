import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/candle_calculator.dart';

void main() {
  test('100 g at 8% for five containers and two or three fragrances', () {
    final two = CandleCalculator.calculate(
      waxGrams: 100,
      loadPercent: 8,
      containerCount: 5,
      fragranceCount: 2,
    );
    expect(two.fragrancePerContainer, 8);
    expect(two.totalWax, 500);
    expect(two.totalFragrance, 40);
    expect(two.eachFragrancePerContainer, 4);
    expect(two.eachFragranceForBatch, 20);

    final three = CandleCalculator.calculate(
      waxGrams: 100,
      loadPercent: 8,
      containerCount: 5,
      fragranceCount: 3,
    );
    expect(three.eachFragrancePerContainer.toStringAsFixed(2), '2.67');
    expect(three.eachFragranceForBatch.toStringAsFixed(2), '13.33');
  });

  test('keeps precision until display', () {
    final result = CandleCalculator.calculate(
      waxGrams: 100.25,
      loadPercent: 7,
      containerCount: 3,
      fragranceCount: 2,
    );
    expect(result.fragrancePerContainer, closeTo(7.0175, 1e-10));
    expect(result.totalWax, 300.75);
    expect(result.totalFragrance, closeTo(21.0525, 1e-10));
    expect(result.eachFragranceForBatch, closeTo(10.52625, 1e-10));
  });

  test('rejects empty, invalid, zero, and negative input', () {
    for (final text in ['', 'abc', '0', '-1', 'NaN']) {
      expect(CandleCalculator.parseWaxGrams(text), isNull);
    }
    for (final text in ['', 'abc', '0', '-1', '1.5']) {
      expect(CandleCalculator.parseContainerCount(text), isNull);
    }
    expect(CandleCalculator.parseWaxGrams('100.5'), 100.5);
    expect(CandleCalculator.parseContainerCount('5'), 5);
    expect(
      () => CandleCalculator.calculate(
        waxGrams: -1,
        loadPercent: 8,
        containerCount: 1,
        fragranceCount: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => CandleCalculator.calculate(
        waxGrams: 1e21,
        loadPercent: 8,
        containerCount: 1,
        fragranceCount: 1,
      ),
      throwsArgumentError,
    );
  });
}
