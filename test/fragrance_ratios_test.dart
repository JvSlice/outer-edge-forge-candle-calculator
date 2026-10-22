import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/candle_calculator.dart';
import 'package:outer_edge_forge_candle_calculator/fragrance_ratios.dart';

void main() {
  test('two sliders always complement each other', () {
    expect(FragranceRatios.adjust([50, 50], 0, 75), ['75', '25']);
    expect(FragranceRatios.adjust([75, 25], 1, 40), ['60', '40']);
    expect(FragranceRatios.adjust([50, 50], 0, 100), ['99.9', '0.1']);
  });

  test('three sliders preserve other shares in proportion and total 100', () {
    expect(FragranceRatios.adjust([50, 30, 20], 0, 70), ['70', '18', '12']);
    final adjusted = FragranceRatios.adjust([33.3, 33.3, 33.4], 0, 50);
    expect(adjusted.first, '50');
    final parsed = CandleCalculator.parseBlendPercentages(adjusted);
    expect(parsed, isNotNull);
    expect(parsed!.reduce((a, b) => a + b), closeTo(100, 1e-8));
    expect(parsed.every((value) => value > 0), isTrue);
    expect(FragranceRatios.equal(3), ['33.33', '33.33', '33.34']);
  });

  test('invalid starting ratios are rejected', () {
    expect(() => FragranceRatios.adjust([75, 30], 0, 70), throwsArgumentError);
  });
}
