import 'dart:math' as math;

/// Keeps slider-controlled fragrance shares positive and totaling 100%.
class FragranceRatios {
  const FragranceRatios._();

  static List<String> equal(int count) => switch (count) {
    1 => ['100'],
    2 => ['50', '50'],
    3 => ['33.33', '33.33', '33.34'],
    _ => throw ArgumentError.value(count, 'count', 'Must be 1–3'),
  };

  static String display(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// Moves one share to the nearest tenth of a percent. Other shares keep
  /// their relative proportions, with rounding assigned to the largest
  /// fractional remainder. Each fragrance retains at least 0.1%.
  static List<String> adjust(List<double> current, int changed, double value) {
    if (current.length < 2 ||
        current.length > 3 ||
        changed < 0 ||
        changed >= current.length ||
        !value.isFinite ||
        current.any((share) => !share.isFinite || share <= 0) ||
        (current.reduce((a, b) => a + b) - 100).abs() > 1e-8) {
      throw ArgumentError(
        'A valid blend of two or three fragrances is required.',
      );
    }
    final count = current.length;
    final selected = (value * 10).round().clamp(1, 1000 - count + 1);
    final remaining = 1000 - selected;
    final otherIndices = [
      for (var i = 0; i < count; i++)
        if (i != changed) i,
    ];
    final weightTotal = otherIndices.fold<double>(
      0,
      (total, i) => total + current[i],
    );
    final extra = remaining - otherIndices.length;
    final units = List<int>.filled(count, 0)..[changed] = selected;
    final fractions = <({int index, double fraction})>[];
    var allocated = 0;
    for (final i in otherIndices) {
      final exact = extra * current[i] / weightTotal;
      final whole = exact.floor();
      units[i] = 1 + whole;
      allocated += whole;
      fractions.add((index: i, fraction: exact - whole));
    }
    fractions.sort((a, b) => b.fraction.compareTo(a.fraction));
    for (var i = 0; i < math.max(0, extra - allocated); i++) {
      units[fractions[i].index]++;
    }
    return units.map((unit) => display(unit / 10)).toList();
  }
}
