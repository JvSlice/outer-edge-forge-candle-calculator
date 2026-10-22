import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/cost_calculator.dart';
import 'package:outer_edge_forge_candle_calculator/recipe.dart';
import 'package:outer_edge_forge_candle_calculator/saved_costs.dart';
import 'package:outer_edge_forge_candle_calculator/cost_pdf_document.dart';

class _MemoryCostStore implements SavedCostStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

SavedCostCalculation _sample(SavedCostRepository repository) {
  final now = DateTime.utc(2026, 10, 22);
  return SavedCostCalculation(
    id: 'cost-a',
    name: 'Autumn candle',
    recipeSnapshot: const CandleRecipe(
      id: 'recipe-a',
      waxType: 'Soy',
      waxGrams: '100',
      loadPercent: 8,
      fragrances: [
        FragrancePart(name: 'Cedar', percent: '60'),
        FragrancePart(name: 'Amber', percent: '40'),
      ],
      wickQuantity: '2',
      costs: CostAssumptions(
        waxPrice: '35',
        waxPounds: '10',
        fragrances: [
          FragranceBottle(price: '10', size: '4'),
          FragranceBottle(price: '12', size: '4'),
        ],
        wickUnitCost: '0.10',
        vesselCost: '1',
        additionalCost: '0.25',
      ),
    ),
    containerCount: 5,
    createdAt: now,
    updatedAt: now,
    linkedRecipeId: 'recipe-a',
    linkedRecipeName: 'Autumn recipe',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'saved snapshots persist unchanged and JSON imports as a copy',
    () async {
      final store = _MemoryCostStore();
      final repo = SavedCostRepository(store: store);
      await repo.save(_sample(repo));
      final restored = (await SavedCostRepository(store: store).load()).single;
      expect(restored.containerCount, 5);
      expect(restored.recipeSnapshot.fragrances[1].percent, '40');
      expect(restored.recipeSnapshot.costs!.fragrances[1].price, '12');
      final count = await repo.importJson(await repo.exportJson());
      expect(count, 1);
      final records = await repo.load();
      expect(records, hasLength(2));
      expect(records.map((item) => item.name).toSet(), {
        'Autumn candle',
        'Autumn candle (imported 1)',
      });
      expect(
        records.last.recipeSnapshot.costs!.fragrances[0].unit,
        BottleUnit.weightOz,
      );
    },
  );

  test(
    'CSV includes unit-bearing assumptions and matching displayed totals',
    () {
      final repo = SavedCostRepository(store: _MemoryCostStore());
      final record = _sample(repo);
      final csv = costCalculationsCsv([record]);
      expect(csv, contains('Wax package lb'));
      expect(csv, contains('Fragrance shares %'));
      expect(csv, contains('Material total USD/batch'));
      final result = CostCalculator.calculate(
        waxGrams: 100,
        loadPercent: 8,
        shares: const [60, 40],
        wickQuantity: 2,
        containerCount: 5,
        costs: record.recipeSnapshot.costs!,
      );
      expect(
        csv,
        contains(CostCalculator.currencyUp(result.materialCostBatch!)),
      );
    },
  );

  test('PDF generation creates a printable snapshot report', () async {
    final bytes = await CostPdfDocument.build(
      _sample(SavedCostRepository(store: _MemoryCostStore())),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
