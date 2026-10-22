import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/recipe.dart';
import 'package:outer_edge_forge_candle_calculator/recipe_repository.dart';

class MemoryStore implements RecipeStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String newValue) async => value = newValue;
}

void main() {
  final twoWick = CandleRecipe(
    id: 'cedar-1',
    name: 'Cedar Evening',
    containerName: 'Amber tumbler',
    containerSize: '8',
    containerUnit: 'oz',
    waxType: 'Soy 464',
    waxGrams: '100',
    loadPercent: 8,
    fragrances: const [
      FragrancePart(name: 'Cedar', percent: '75'),
      FragrancePart(name: 'Amber', percent: '25'),
    ],
    wickQuantity: '2',
    wickSeries: 'CD',
    wickSize: '8',
    wickSpacing: '1.5',
    wickSpacingUnit: 'in',
    fragranceTemperature: '185',
    pourTemperature: '135',
    temperatureUnit: '°F',
    notes: 'Test burn after 48 hours.',
  );

  test('two-wick recipe survives a new repository instance', () async {
    final store = MemoryStore();
    await RecipeRepository(store).save(twoWick);
    final reopened = await RecipeRepository(store).load();
    expect(reopened, hasLength(1));
    final recipe = reopened.single;
    expect(recipe.containerName, 'Amber tumbler');
    expect(recipe.containerSize, '8');
    expect(recipe.containerUnit, 'oz');
    expect(recipe.waxType, 'Soy 464');
    expect(recipe.waxGrams, '100');
    expect(recipe.wickQuantity, '2');
    expect(recipe.wickSeries, 'CD');
    expect(recipe.wickSize, '8');
    expect(recipe.wickSpacing, '1.5');
    expect(recipe.wickSpacingUnit, 'in');
    expect(recipe.fragranceTemperature, '185');
    expect(recipe.pourTemperature, '135');
    expect(recipe.temperatureUnit, '°F');
    expect(recipe.fragrances.map((part) => part.percent), ['75', '25']);
    expect(recipe.fragrances.map((part) => part.name), ['Cedar', 'Amber']);
    expect(recipe.notes, 'Test burn after 48 hours.');
  });

  test('drafts, edit, duplicate, and delete are explicit', () async {
    final store = MemoryStore();
    final repo = RecipeRepository(store);
    final draft = CandleRecipe(id: repo.newId());
    await repo.save(draft);
    expect((await repo.load()).single.waxGrams, '');
    await repo.save(draft.copyWith(name: 'First draft', waxGrams: '100'));
    expect((await repo.load()).single.name, 'First draft');
    final copy = await repo.duplicate((await repo.load()).single);
    expect(copy.id, isNot(draft.id));
    expect(copy.name, 'First draft (copy)');
    expect(await repo.load(), hasLength(2));
    await repo.delete(draft.id);
    expect((await repo.load()).single.id, copy.id);
  });

  test('import validates backup and keeps duplicates as copies', () async {
    final store = MemoryStore();
    final repo = RecipeRepository(store);
    await repo.save(twoWick);
    final backup = await repo.exportJson();
    final plan = await repo.inspectImport(backup);
    expect(plan.count, 1);
    expect(plan.duplicateCount, 1);
    await repo.importAsCopies(plan);
    final recipes = await repo.load();
    expect(recipes, hasLength(2));
    expect(recipes.first.name, 'Cedar Evening');
    expect(recipes.last.name, 'Cedar Evening (imported)');
    expect(recipes.last.id, isNot(recipes.first.id));
    expect(recipes.last.fragrances[0].percent, '75');

    expect(() => RecipeBackup.parse('not json'), throwsFormatException);
    expect(
      () => RecipeBackup.parse(
        '{"format":"oef-candle-recipes","version":2,"recipes":[]}',
      ),
      throwsFormatException,
    );
    expect(
      () => RecipeBackup.parse(
        backup.replaceFirst('"loadPercent": 8', '"loadPercent": "8"'),
      ),
      throwsFormatException,
    );
    expect(
      () => RecipeBackup.parse(
        backup.replaceFirst('"waxGrams": "100"', '"waxGrams": "0"'),
      ),
      throwsFormatException,
    );
    expect(
      () => RecipeBackup.parse(
        backup.replaceFirst('"wickQuantity": "2"', '"wickQuantity": "1.5"'),
      ),
      throwsFormatException,
    );
    final doubleId = RecipeBackup([twoWick, twoWick]).toJsonString();
    expect(() => RecipeBackup.parse(doubleId), throwsFormatException);
  });

  test(
    'library limit rejects writes without corrupting saved recipes',
    () async {
      final store = MemoryStore();
      store.value = RecipeBackup(
        List.generate(500, (index) => CandleRecipe(id: 'recipe-$index')),
      ).toJsonString();
      final repo = RecipeRepository(store);
      await expectLater(
        repo.save(const CandleRecipe(id: 'overflow')),
        throwsFormatException,
      );
      final plan = await repo.inspectImport(
        RecipeBackup(const [CandleRecipe(id: 'external')]).toJsonString(),
      );
      await expectLater(repo.importAsCopies(plan), throwsFormatException);
      expect(await repo.load(), hasLength(500));
    },
  );
}
