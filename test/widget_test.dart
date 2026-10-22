import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/main.dart';
import 'package:outer_edge_forge_candle_calculator/cost_calculator.dart';
import 'package:outer_edge_forge_candle_calculator/recipe.dart';
import 'package:outer_edge_forge_candle_calculator/recipe_pages.dart';
import 'package:outer_edge_forge_candle_calculator/recipe_repository.dart';

class _MemoryStore implements RecipeStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String newValue) async => value = newValue;
}

void main() {
  CandleApp app() =>
      CandleApp(recipeRepository: RecipeRepository(_MemoryStore()));

  Future<void> openCalculator(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('welcome-screen')));
    await tester.pumpAndSettle();
  }

  String value(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('welcome opens with $key', (tester) async {
      await tester.pumpWidget(app());
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

  testWidgets('moving a blend slider updates its partner and amounts', (
    tester,
  ) async {
    await openCalculator(tester);
    await tester.enterText(find.byKey(const Key('wax-weight')), '100');
    await tester.ensureVisible(find.byKey(const Key('split-button')));
    await tester.tap(find.byKey(const Key('split-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('fragrance-count')));
    await tester.tap(find.byKey(const Key('fragrance-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 fragrances').last);
    await tester.pumpAndSettle();
    final first = find.byKey(const Key('fragrance-slider-0'));
    await tester.ensureVisible(first);
    expect(tester.widget<Slider>(first).divisions, 98);
    await tester.drag(first, const Offset(70, 0));
    await tester.pumpAndSettle();
    final firstShare = tester.widget<Slider>(first).value;
    final secondShare = tester
        .widget<Slider>(find.byKey(const Key('fragrance-slider-1')))
        .value;
    expect(firstShare, greaterThan(50));
    expect(firstShare, firstShare.roundToDouble());
    expect(secondShare, secondShare.roundToDouble());
    expect(firstShare + secondShare, closeTo(100, 1e-8));
    expect(
      value(tester, 'split-per-container'),
      '${(8 * firstShare / 100).toStringAsFixed(2)} g',
    );
  });

  testWidgets('incomplete recipe can reset shares before saving', (
    tester,
  ) async {
    final repository = RecipeRepository(_MemoryStore());
    await tester.pumpWidget(
      MaterialApp(
        home: RecipeEditorPage(
          repository: repository,
          recipe: const CandleRecipe(
            id: 'draft',
            fragrances: [
              FragrancePart(name: 'Cedar', percent: '75'),
              FragrancePart(name: 'Amber', percent: ''),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Blend shares must be positive and add up to 100%.'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('recipe-fragrance-slider-reset')),
    );
    await tester.tap(find.byKey(const Key('recipe-fragrance-slider-reset')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Slider>(find.byKey(const Key('recipe-fragrance-slider-0')))
          .value,
      50,
    );
    await tester.ensureVisible(find.byKey(const Key('save-recipe')));
    await tester.tap(find.byKey(const Key('save-recipe')));
    await tester.pumpAndSettle();
    expect(
      (await repository.load()).single.fragrances
          .map((part) => part.percent)
          .toList(),
      ['50', '50'],
    );
  });

  testWidgets('loading a 75/25 recipe keeps batch count and saves explicitly', (
    tester,
  ) async {
    final repository = RecipeRepository(_MemoryStore());
    await repository.save(
      const CandleRecipe(
        id: 'two-wick',
        name: 'Cedar Evening',
        waxGrams: '100',
        loadPercent: 8,
        fragrances: [
          FragrancePart(name: 'Cedar', percent: '75'),
          FragrancePart(name: 'Amber', percent: '25'),
        ],
        wickQuantity: '2',
        wickSpacing: '1.5',
        wickSpacingUnit: 'in',
      ),
    );
    await tester.pumpWidget(CandleApp(recipeRepository: repository));
    await tester.tap(find.byKey(const Key('welcome-screen')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('container-count')), '5');
    await tester.tap(find.byKey(const Key('recipes-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-two-wick')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('wax-weight')))
          .controller!
          .text,
      '100',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('container-count')))
          .controller!
          .text,
      '5',
    );
    expect(
      tester.widget<Slider>(find.byKey(const Key('fragrance-slider-0'))).value,
      75,
    );
    expect(
      tester.widget<Slider>(find.byKey(const Key('fragrance-slider-1'))).value,
      25,
    );
    expect(value(tester, 'total-wax'), '500.00 g');
    expect(value(tester, 'total-fragrance'), '40.00 g');
    expect(value(tester, 'split-per-container'), '6.00 g');
    expect(value(tester, 'split-per-container-1'), '2.00 g');
    expect(value(tester, 'split-per-batch'), '30.00 g');
    expect(value(tester, 'split-per-batch-1'), '10.00 g');

    await tester.enterText(find.byKey(const Key('wax-weight')), '120');
    await tester.pumpAndSettle();
    expect((await repository.load()).single.waxGrams, '100');
    final firstSlider = find.byKey(const Key('fragrance-slider-0'));
    await tester.ensureVisible(firstSlider);
    await tester.drag(firstSlider, const Offset(-50, 0));
    await tester.pumpAndSettle();
    final adjustedShare = tester.widget<Slider>(firstSlider).value;
    expect(adjustedShare, lessThan(75));
    await tester.ensureVisible(find.byKey(const Key('save-changes-button')));
    await tester.tap(find.byKey(const Key('save-changes-button')));
    await tester.pumpAndSettle();
    expect((await repository.load()).single.waxGrams, '120');
    final savedShares = (await repository.load()).single.fragrances
        .map((part) => double.parse(part.percent))
        .toList();
    expect(savedShares.first, adjustedShare);
    expect(savedShares.reduce((a, b) => a + b), closeTo(100, 1e-8));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('container-count')))
          .controller!
          .text,
      '5',
    );
  });

  testWidgets('calculator save preserves newer linked cost assumptions', (
    tester,
  ) async {
    final repository = RecipeRepository(_MemoryStore());
    const recipe = CandleRecipe(
      id: 'costed',
      name: 'Costed candle',
      waxGrams: '100',
      fragrances: [FragrancePart(name: 'Cedar', percent: '100')],
    );
    await repository.save(recipe);
    await tester.pumpWidget(CandleApp(recipeRepository: repository));
    await tester.tap(find.byKey(const Key('welcome-screen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipes-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-costed')));
    await tester.pumpAndSettle();
    await repository.save(
      recipe.copyWith(
        costs: const CostAssumptions(waxPrice: '35', waxPounds: '10'),
      ),
    );
    await tester.enterText(find.byKey(const Key('wax-weight')), '120');
    await tester.ensureVisible(find.byKey(const Key('save-changes-button')));
    await tester.tap(find.byKey(const Key('save-changes-button')));
    await tester.pumpAndSettle();
    final saved = (await repository.load()).single;
    expect(saved.waxGrams, '120');
    expect(saved.costs!.waxPrice, '35');
  });

  testWidgets('creating two drafts gives each a separate saved ID', (
    tester,
  ) async {
    final repository = RecipeRepository(_MemoryStore());
    await tester.pumpWidget(
      MaterialApp(
        home: RecipeLibraryPage(
          repository: repository,
          newRecipeTemplate: const CandleRecipe(id: 'template'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['First draft', 'Second draft']) {
      await tester.tap(find.byKey(const Key('create-recipe')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('recipe-name')), name);
      await tester.ensureVisible(find.byKey(const Key('save-recipe')));
      await tester.tap(find.byKey(const Key('save-recipe')));
      await tester.pumpAndSettle();
    }
    final recipes = await repository.load();
    expect(recipes.map((recipe) => recipe.name), [
      'First draft',
      'Second draft',
    ]);
    expect(recipes.map((recipe) => recipe.id).toSet(), hasLength(2));
  });
}
