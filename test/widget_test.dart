import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/main.dart';
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
      tester
          .widget<TextField>(find.byKey(const Key('fragrance-percent-0')))
          .controller!
          .text,
      '75',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('fragrance-percent-1')))
          .controller!
          .text,
      '25',
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
    await tester.ensureVisible(find.byKey(const Key('save-changes-button')));
    await tester.tap(find.byKey(const Key('save-changes-button')));
    await tester.pumpAndSettle();
    expect((await repository.load()).single.waxGrams, '120');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('container-count')))
          .controller!
          .text,
      '5',
    );
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
