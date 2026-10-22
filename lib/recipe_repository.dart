import 'package:shared_preferences/shared_preferences.dart';

import 'recipe.dart';

abstract class RecipeStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesRecipeStore implements RecipeStore {
  SharedPreferencesRecipeStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  // GitHub Pages apps share an origin, so this key is specific to OEF Candles.
  static const key = 'outer_edge_forge_candle_calculator.recipes.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class RecipeImportPlan {
  const RecipeImportPlan(this.backup, this.duplicateCount);

  final RecipeBackup backup;
  final int duplicateCount;
  int get count => backup.recipes.length;
}

class RecipeRepository {
  RecipeRepository(this.store);

  final RecipeStore store;
  int _idCounter = 0;

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${(_idCounter++).toRadixString(36)}';

  Future<List<CandleRecipe>> load() async {
    final text = await store.read();
    if (text == null) return [];
    return RecipeBackup.parse(text).recipes;
  }

  Future<void> save(CandleRecipe recipe) async {
    CandleRecipe.fromJson(recipe.toJson());
    final recipes = await load();
    final index = recipes.indexWhere((item) => item.id == recipe.id);
    if (index < 0) {
      if (recipes.length >= 500) {
        throw const FormatException('Recipe library is full (500 maximum).');
      }
      recipes.add(recipe);
    } else {
      recipes[index] = recipe;
    }
    await store.write(RecipeBackup(recipes).toJsonString());
  }

  Future<CandleRecipe> duplicate(CandleRecipe recipe) async {
    final copy = recipe.copyWith(
      id: newId(),
      name: '${recipe.displayName} (copy)',
    );
    await save(copy);
    return copy;
  }

  Future<void> delete(String id) async {
    final recipes = await load();
    recipes.removeWhere((recipe) => recipe.id == id);
    await store.write(RecipeBackup(recipes).toJsonString());
  }

  Future<String> exportJson() async =>
      RecipeBackup(await load()).toJsonString();

  Future<RecipeImportPlan> inspectImport(String text) async {
    final backup = RecipeBackup.parse(text);
    final existing = await load();
    final ids = existing.map((recipe) => recipe.id).toSet();
    final names = existing
        .map((recipe) => recipe.displayName.toLowerCase())
        .toSet();
    final duplicates = backup.recipes.where(
      (recipe) =>
          ids.contains(recipe.id) ||
          names.contains(recipe.displayName.toLowerCase()),
    );
    return RecipeImportPlan(backup, duplicates.length);
  }

  /// Imports every recipe as a new record; existing records are never replaced.
  Future<int> importAsCopies(RecipeImportPlan plan) async {
    final recipes = await load();
    if (recipes.length + plan.count > 500) {
      throw const FormatException('Import would exceed the 500-recipe limit.');
    }
    final names = recipes
        .map((recipe) => recipe.displayName.toLowerCase())
        .toSet();
    for (final incoming in plan.backup.recipes) {
      var name = incoming.name;
      if (names.contains(incoming.displayName.toLowerCase())) {
        final stem = incoming.displayName;
        var number = 1;
        do {
          name = '$stem (imported${number == 1 ? '' : ' $number'})';
          number++;
        } while (names.contains(name.toLowerCase()));
      }
      names.add(name.trim().isEmpty ? 'untitled recipe' : name.toLowerCase());
      recipes.add(incoming.copyWith(id: newId(), name: name));
    }
    await store.write(RecipeBackup(recipes).toJsonString());
    return plan.count;
  }
}
