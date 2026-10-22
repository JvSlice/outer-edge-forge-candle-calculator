import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/cost_page.dart';
import 'package:outer_edge_forge_candle_calculator/recipe.dart';
import 'package:outer_edge_forge_candle_calculator/recipe_repository.dart';
import 'package:outer_edge_forge_candle_calculator/saved_costs.dart';

class _MemoryStore implements RecipeStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String newValue) async => value = newValue;
}

class _MemoryCostStore implements SavedCostStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String newValue) async => value = newValue;
}

void main() {
  testWidgets('cost screen fits a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CostPage(
          repository: RecipeRepository(_MemoryStore()),
          initialRecipe: const CandleRecipe(
            id: 'mobile',
            waxGrams: '100',
            wickQuantity: '2',
            fragrances: [
              FragrancePart(name: 'Cedar', percent: '75'),
              FragrancePart(name: 'Amber', percent: '25'),
            ],
          ),
          initialContainers: '5',
          savedCostRepository: SavedCostRepository(store: _MemoryCostStore()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Full batch'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone cost screen shows the acceptance amounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CostPage(
          repository: RecipeRepository(_MemoryStore()),
          initialRecipe: const CandleRecipe(
            id: 'one-off',
            waxGrams: '100',
            wickQuantity: '2',
          ),
          initialContainers: '5',
          savedCostRepository: SavedCostRepository(store: _MemoryCostStore()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cost-waxPrice')), '35');
    await tester.enterText(find.byKey(const Key('cost-waxPounds')), '10');
    await tester.enterText(
      find.byKey(const Key('cost-fragrance-0-price')),
      '10',
    );
    await tester.enterText(find.byKey(const Key('cost-fragrance-0-size')), '4');
    await tester.enterText(find.byKey(const Key('cost-wickCost')), '0.10');
    await tester.enterText(find.byKey(const Key('cost-vesselCost')), '1');
    await tester.pumpAndSettle();
    expect(find.text('\$0.78'), findsOneWidget);
    expect(find.text('\$0.71'), findsWidgets);
    expect(find.text('\$2.68'), findsOneWidget);
    expect(find.text('\$13.39'), findsOneWidget);
    expect(find.text('500.00 g'), findsOneWidget);
    expect(find.text('40.00 g'), findsWidgets);
  });

  testWidgets(
    'linked costs save explicitly without saving one-off quantities',
    (tester) async {
      final repository = RecipeRepository(_MemoryStore());
      await repository.save(
        const CandleRecipe(
          id: 'saved',
          name: 'Cedar Evening',
          waxType: 'Soy 464',
          waxGrams: '100',
          wickQuantity: '2',
          fragrances: [FragrancePart(name: 'Cedar', percent: '100')],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CostPage(
            repository: repository,
            initialRecipe: const CandleRecipe(id: 'one-off'),
            initialContainers: '5',
            savedCostRepository: SavedCostRepository(store: _MemoryCostStore()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cost-recipe-standalone')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cedar Evening').last);
      await tester.pumpAndSettle();
      expect(find.text('Loaded: Cedar Evening'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('cost-waxGrams')))
            .controller!
            .text,
        '100',
      );
      await tester.enterText(find.byKey(const Key('cost-waxGrams')), '120');
      await tester.enterText(find.byKey(const Key('cost-waxPrice')), '35');
      await tester.enterText(find.byKey(const Key('cost-waxPounds')), '10');
      await tester.pumpAndSettle();
      expect(find.textContaining('Unsaved cost changes'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('save-recipe-costs')));
      await tester.tap(find.byKey(const Key('save-recipe-costs')));
      await tester.pumpAndSettle();
      final saved = (await repository.load()).single;
      expect(saved.waxGrams, '100');
      expect(saved.costs!.waxPrice, '35');
      expect(saved.costs!.waxPounds, '10');
      expect(find.text('One-off quantity changes'), findsOneWidget);
    },
  );

  testWidgets('saves and reloads an independent cost snapshot', (tester) async {
    final savedStore = _MemoryCostStore();
    final savedCosts = SavedCostRepository(store: savedStore);
    await tester.pumpWidget(
      MaterialApp(
        home: CostPage(
          repository: RecipeRepository(_MemoryStore()),
          savedCostRepository: savedCosts,
          initialRecipe: const CandleRecipe(
            id: 'snapshot-source',
            name: 'Autumn pour',
            waxType: 'Soy',
            waxGrams: '100',
            wickQuantity: '2',
            fragrances: [FragrancePart(name: 'Cedar', percent: '100')],
          ),
          initialContainers: '5',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-cost-calculation')));
    await tester.tap(find.byKey(const Key('save-cost-calculation')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Autumn snapshot');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    final records = await savedCosts.load();
    expect(records, hasLength(1));
    expect(records.single.name, 'Autumn snapshot');
    expect(records.single.containerCount, 5);
    expect(records.single.recipeSnapshot.waxGrams, '100');
    expect(records.single.linkedRecipeName, isNull);
    expect(find.text('Autumn snapshot'), findsOneWidget);
  });
}
