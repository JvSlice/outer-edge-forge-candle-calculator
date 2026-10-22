import 'candle_calculator.dart';
import 'recipe.dart';

/// Quantities for a printout. The saved recipe remains unchanged.
class RecipePrintData {
  RecipePrintData._({required this.recipe, required this.batchCount}) {
    waxPerContainer = CandleCalculator.parseWaxGrams(recipe.waxGrams);
    final wax = waxPerContainer;
    fragrancePerContainer = wax == null
        ? null
        : CandleCalculator.fragrancePerContainer(wax, recipe.loadPercent);
    batchWax = wax == null ? null : wax * batchCount;
    batchFragrance = fragrancePerContainer == null
        ? null
        : fragrancePerContainer! * batchCount;
    final shares = CandleCalculator.parseBlendPercentages(
      recipe.fragrances.map((part) => part.percent).toList(),
    );
    fragrances = List.generate(recipe.fragrances.length, (index) {
      final part = recipe.fragrances[index];
      final share = shares == null ? null : shares[index];
      final eachPerContainer = share == null || fragrancePerContainer == null
          ? null
          : fragrancePerContainer! * share / 100;
      return RecipeFragrancePrintData(
        name: part.name.trim().isEmpty
            ? 'Fragrance ${index + 1}'
            : part.name.trim(),
        sharePercent: share,
        perContainerGrams: eachPerContainer,
        batchGrams: eachPerContainer == null
            ? null
            : eachPerContainer * batchCount,
      );
    });
  }

  factory RecipePrintData.forBatch(CandleRecipe recipe, int batchCount) {
    if (batchCount <= 0) {
      throw ArgumentError.value(batchCount, 'batchCount', 'Must be positive');
    }
    return RecipePrintData._(recipe: recipe, batchCount: batchCount);
  }

  final CandleRecipe recipe;
  final int batchCount;
  late final double? waxPerContainer;
  late final double? fragrancePerContainer;
  late final double? batchWax;
  late final double? batchFragrance;
  late final List<RecipeFragrancePrintData> fragrances;
}

class RecipeFragrancePrintData {
  const RecipeFragrancePrintData({
    required this.name,
    required this.sharePercent,
    required this.perContainerGrams,
    required this.batchGrams,
  });

  final String name;
  final double? sharePercent;
  final double? perContainerGrams;
  final double? batchGrams;
}
