import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/cost_calculator.dart';

void main() {
  test('acceptance quantities and unrounded batch total', () {
    final result = CostCalculator.calculate(
      waxGrams: 100,
      loadPercent: 8,
      shares: [100],
      wickQuantity: 2,
      containerCount: 5,
      costs: const CostAssumptions(
        waxPrice: '35',
        waxPounds: '10',
        fragrances: [FragranceBottle(price: '10', size: '4')],
        wickUnitCost: '0.10',
        vesselCost: '1.00',
        additionalCost: '0',
      ),
    );
    expect(result.waxCost!.toStringAsFixed(2), '0.77');
    expect(result.fragranceCost!.toStringAsFixed(2), '0.71');
    expect(result.wickCost!.toStringAsFixed(2), '0.20');
    expect(result.vesselCost!.toStringAsFixed(2), '1.00');
    expect(result.materialCostPerContainer!.toStringAsFixed(2), '2.68');
    // The issue lists $13.38, but the specified conversions give $13.385485…
    // and conventional two-decimal rounding therefore displays $13.39.
    expect(result.materialCostBatch!.toStringAsFixed(2), '13.39');
    expect(result.waxGramsBatch, 500);
    expect(result.fragranceGramsBatch, 40);
    expect(result.fragranceGramsEach.single * 5, 40);
    expect(result.missing, isEmpty);
  });

  test('unequal blends use separate bottle prices', () {
    final result = CostCalculator.calculate(
      waxGrams: 100,
      loadPercent: 8,
      shares: [75, 25],
      wickQuantity: 2,
      containerCount: 5,
      costs: const CostAssumptions(
        waxPrice: '0',
        waxPounds: '1',
        fragrances: [
          FragranceBottle(price: '10', size: '4'),
          FragranceBottle(price: '20', size: '2'),
        ],
        wickUnitCost: '0',
        vesselCost: '0',
        additionalCost: '0',
      ),
    );
    expect(result.fragranceGramsEach, [6, 2]);
    expect(
      result.fragranceCosts[0],
      closeTo(6 * 10 / (4 * 28.349523125), 1e-12),
    );
    expect(
      result.fragranceCosts[1],
      closeTo(2 * 20 / (2 * 28.349523125), 1e-12),
    );
    expect(
      result.fragranceCost,
      closeTo(result.fragranceCosts[0]! + result.fragranceCosts[1]!, 1e-12),
    );
    expect(result.waxCost, 0);
    expect(result.materialCostBatch, isNotNull);
  });

  test('fluid ounces need density or net weight and never use oz mass', () {
    CostResult calculate(FragranceBottle bottle) => CostCalculator.calculate(
      waxGrams: 100,
      loadPercent: 8,
      shares: [100],
      wickQuantity: 1,
      containerCount: 1,
      costs: CostAssumptions(
        waxPrice: '0',
        waxPounds: '1',
        fragrances: [bottle],
        wickUnitCost: '0',
        vesselCost: '0',
        additionalCost: '0',
      ),
    );
    final missing = calculate(
      const FragranceBottle(price: '10', size: '4', unit: BottleUnit.fluidOz),
    );
    expect(missing.fragranceCost, isNull);
    expect(missing.materialCostPerContainer, isNull);
    expect(missing.missing, contains('fragrance 1 density or net weight'));
    final density = calculate(
      const FragranceBottle(
        price: '10',
        size: '4',
        unit: BottleUnit.fluidOz,
        density: '0.9',
      ),
    );
    expect(
      density.fragranceCost,
      closeTo(8 * 10 / (4 * 29.5735295625 * 0.9), 1e-12),
    );
    final net = calculate(
      const FragranceBottle(
        price: '10',
        size: '4',
        unit: BottleUnit.fluidOz,
        density: '0.9',
        netGrams: '100',
      ),
    );
    expect(net.fragranceCost, closeTo(0.8, 1e-12));
  });

  test('missing costs keep totals incomplete; zero price is valid', () {
    final result = CostCalculator.calculate(
      waxGrams: 100,
      loadPercent: 8,
      shares: [100],
      wickQuantity: 1,
      containerCount: 1,
      costs: const CostAssumptions(
        waxPrice: '0',
        waxPounds: '1',
        fragrances: [FragranceBottle(price: '', size: '4')],
        wickUnitCost: '0',
        vesselCost: '0',
        additionalCost: '0',
      ),
    );
    expect(result.waxCost, 0);
    expect(result.fragranceCost, isNull);
    expect(result.materialCostPerContainer, isNull);
    expect(result.missing, contains('fragrance 1 bottle price'));
    expect(
      () => CostCalculator.calculate(
        waxGrams: 100,
        loadPercent: 8,
        shares: [75, 30],
        wickQuantity: 1,
        containerCount: 1,
        costs: const CostAssumptions(
          fragrances: [FragranceBottle(), FragranceBottle()],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('renaming a fragrance clears only its bottle assumption', () {
    const costs = CostAssumptions(
      fragrances: [
        FragranceBottle(price: '10', size: '4'),
        FragranceBottle(price: '20', size: '2'),
      ],
    );
    final aligned = costs.alignedToNames(['Cedar', 'Amber'], ['Cedar', 'Rose']);
    expect(aligned.fragrances[0].price, '10');
    expect(aligned.fragrances[1].price, '');
  });
}
