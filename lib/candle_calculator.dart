/// Entered wax weight excludes fragrance.
class CandleCalculator {
  const CandleCalculator._();

  static double fragrancePerContainer(double waxGrams, int loadPercent) =>
      waxGrams * loadPercent / 100;

  static double eachFragrance(double totalFragrance, int fragranceCount) =>
      totalFragrance / fragranceCount;

  static List<double>? parseBlendPercentages(List<String> entries) {
    if (entries.isEmpty || entries.length > 3) return null;
    final values = <double>[];
    for (final entry in entries) {
      final value = double.tryParse(entry.trim());
      if (value == null || !value.isFinite || value <= 0 || value > 100) {
        return null;
      }
      values.add(value);
    }
    final sum = values.fold<double>(0, (total, value) => total + value);
    return (sum - 100).abs() <= 1e-8 ? values : null;
  }

  static List<double> blendAmounts(
    double totalFragrance,
    List<double> percents,
  ) {
    if (!totalFragrance.isFinite ||
        totalFragrance < 0 ||
        parseBlendPercentages(percents.map((value) => '$value').toList()) ==
            null) {
      throw ArgumentError('Blend percentages must total 100%.');
    }
    return percents.map((percent) => totalFragrance * percent / 100).toList();
  }

  static double? parseWaxGrams(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  static int? parseContainerCount(String text) {
    final value = int.tryParse(text.trim());
    return value != null && value > 0 ? value : null;
  }

  static CandleAmounts calculate({
    required double waxGrams,
    required int loadPercent,
    required int containerCount,
    required int fragranceCount,
    List<double>? blendPercentages,
  }) {
    if (!waxGrams.isFinite || waxGrams <= 0) {
      throw ArgumentError.value(waxGrams, 'waxGrams', 'Must be positive');
    }
    if (loadPercent < 6 || loadPercent > 10) {
      throw ArgumentError.value(loadPercent, 'loadPercent', 'Must be 6–10');
    }
    if (containerCount <= 0) {
      throw ArgumentError.value(
        containerCount,
        'containerCount',
        'Must be positive',
      );
    }
    if (fragranceCount < 1 || fragranceCount > 3) {
      throw ArgumentError.value(
        fragranceCount,
        'fragranceCount',
        'Must be 1–3',
      );
    }
    if (blendPercentages != null && blendPercentages.length != fragranceCount) {
      throw ArgumentError('Blend count does not match fragrance count.');
    }

    final fragrancePerContainer = CandleCalculator.fragrancePerContainer(
      waxGrams,
      loadPercent,
    );
    final totalWax = waxGrams * containerCount;
    final totalFragrance = fragrancePerContainer * containerCount;
    if (![
      fragrancePerContainer,
      totalWax,
      totalFragrance,
    ].every((amount) => amount.isFinite && amount < 1e21)) {
      throw ArgumentError('Amounts are too large to calculate.');
    }

    return CandleAmounts(
      fragrancePerContainer: fragrancePerContainer,
      totalWax: totalWax,
      totalFragrance: totalFragrance,
      eachFragrancePerContainer: eachFragrance(
        fragrancePerContainer,
        fragranceCount,
      ),
      eachFragranceForBatch: eachFragrance(totalFragrance, fragranceCount),
      blendPerContainer: blendAmounts(
        fragrancePerContainer,
        blendPercentages ?? List.filled(fragranceCount, 100 / fragranceCount),
      ),
      blendForBatch: blendAmounts(
        totalFragrance,
        blendPercentages ?? List.filled(fragranceCount, 100 / fragranceCount),
      ),
    );
  }
}

class CandleAmounts {
  const CandleAmounts({
    required this.fragrancePerContainer,
    required this.totalWax,
    required this.totalFragrance,
    required this.eachFragrancePerContainer,
    required this.eachFragranceForBatch,
    required this.blendPerContainer,
    required this.blendForBatch,
  });

  final double fragrancePerContainer;
  final double totalWax;
  final double totalFragrance;
  final double eachFragrancePerContainer;
  final double eachFragranceForBatch;
  final List<double> blendPerContainer;
  final List<double> blendForBatch;
}
