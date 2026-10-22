import 'candle_calculator.dart';

enum BottleUnit { weightOz, fluidOz }

class FragranceBottle {
  const FragranceBottle({
    this.price = '',
    this.size = '',
    this.unit = BottleUnit.weightOz,
    this.density = '',
    this.netGrams = '',
  });

  final String price;
  final String size;
  final BottleUnit unit;
  final String density; // g/mL, for fluid ounces only
  final String netGrams; // Alternative to density for fluid ounces

  FragranceBottle copyWith({
    String? price,
    String? size,
    BottleUnit? unit,
    String? density,
    String? netGrams,
  }) => FragranceBottle(
    price: price ?? this.price,
    size: size ?? this.size,
    unit: unit ?? this.unit,
    density: density ?? this.density,
    netGrams: netGrams ?? this.netGrams,
  );

  Map<String, Object> toJson() => {
    'price': price,
    'size': size,
    'unit': unit.name,
    'density': density,
    'netGrams': netGrams,
  };

  factory FragranceBottle.fromJson(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid fragrance cost.');
    }
    final map = Map<String, Object?>.from(value);
    String field(String key) => _field(map, key);
    final unit = BottleUnit.values.where((item) => item.name == map['unit']);
    if (unit.length != 1) throw const FormatException('Invalid bottle unit.');
    final bottle = FragranceBottle(
      price: field('price'),
      size: field('size'),
      unit: unit.single,
      density: field('density'),
      netGrams: field('netGrams'),
    );
    _checkNumber(bottle.price, 'Fragrance price', allowZero: true);
    _checkNumber(bottle.size, 'Bottle size');
    _checkNumber(bottle.density, 'Fragrance density');
    _checkNumber(bottle.netGrams, 'Net fragrance weight');
    return bottle;
  }
}

class CostAssumptions {
  const CostAssumptions({
    this.waxPrice = '',
    this.waxPounds = '',
    this.fragrances = const [FragranceBottle()],
    this.wickUnitCost = '',
    this.vesselCost = '',
    this.additionalCost = '0',
  });

  final String waxPrice;
  final String waxPounds;
  final List<FragranceBottle> fragrances;
  final String wickUnitCost;
  final String vesselCost;
  final String additionalCost;

  CostAssumptions copyWith({
    String? waxPrice,
    String? waxPounds,
    List<FragranceBottle>? fragrances,
    String? wickUnitCost,
    String? vesselCost,
    String? additionalCost,
  }) => CostAssumptions(
    waxPrice: waxPrice ?? this.waxPrice,
    waxPounds: waxPounds ?? this.waxPounds,
    fragrances: fragrances ?? this.fragrances,
    wickUnitCost: wickUnitCost ?? this.wickUnitCost,
    vesselCost: vesselCost ?? this.vesselCost,
    additionalCost: additionalCost ?? this.additionalCost,
  );

  /// Keep a bottle price only while its fragrance occupies the same slot.
  CostAssumptions alignedToNames(List<String> before, List<String> after) =>
      copyWith(
        fragrances: [
          for (var i = 0; i < after.length; i++)
            i < before.length && i < fragrances.length && before[i] == after[i]
                ? fragrances[i]
                : const FragranceBottle(),
        ],
      );

  Map<String, Object> toJson() => {
    'waxPrice': waxPrice,
    'waxPounds': waxPounds,
    'fragrances': fragrances.map((item) => item.toJson()).toList(),
    'wickUnitCost': wickUnitCost,
    'vesselCost': vesselCost,
    'additionalCost': additionalCost,
  };

  factory CostAssumptions.fromJson(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid cost assumptions.');
    }
    final map = Map<String, Object?>.from(value);
    final bottles = map['fragrances'];
    if (bottles is! List || bottles.isEmpty || bottles.length > 3) {
      throw const FormatException('Cost assumptions need 1–3 fragrance slots.');
    }
    final assumptions = CostAssumptions(
      waxPrice: _field(map, 'waxPrice'),
      waxPounds: _field(map, 'waxPounds'),
      fragrances: bottles.map(FragranceBottle.fromJson).toList(),
      wickUnitCost: _field(map, 'wickUnitCost'),
      vesselCost: _field(map, 'vesselCost'),
      additionalCost: _field(map, 'additionalCost'),
    );
    _checkNumber(assumptions.waxPrice, 'Wax price', allowZero: true);
    _checkNumber(assumptions.waxPounds, 'Wax package weight');
    _checkNumber(assumptions.wickUnitCost, 'Wick cost', allowZero: true);
    _checkNumber(assumptions.vesselCost, 'Vessel cost', allowZero: true);
    _checkNumber(
      assumptions.additionalCost,
      'Additional cost',
      allowZero: true,
    );
    return assumptions;
  }
}

String _field(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.length > 40) {
    throw FormatException('Invalid cost field: $key.');
  }
  return value;
}

void _checkNumber(String text, String label, {bool allowZero = false}) {
  if (text.trim().isEmpty) return;
  final value = double.tryParse(text.trim());
  if (value == null ||
      !value.isFinite ||
      value < 0 ||
      (!allowZero && value == 0)) {
    throw FormatException(
      '$label must be ${allowZero ? 'nonnegative' : 'positive'}.',
    );
  }
}

class CostResult {
  const CostResult({
    required this.waxGramsBatch,
    required this.fragranceGramsBatch,
    required this.fragranceGramsEach,
    required this.waxCost,
    required this.fragranceCosts,
    required this.wickCost,
    required this.vesselCost,
    required this.additionalCost,
    required this.containerCount,
    required this.missing,
  });

  final double waxGramsBatch;
  final double fragranceGramsBatch;
  final List<double> fragranceGramsEach;
  final double? waxCost;
  final List<double?> fragranceCosts;
  final double? wickCost;
  final double? vesselCost;
  final double? additionalCost;
  final int containerCount;
  final List<String> missing;

  double? get fragranceCost => fragranceCosts.every((item) => item != null)
      ? fragranceCosts.fold<double>(0, (sum, item) => sum + item!)
      : null;

  double? get materialCostPerContainer {
    final fragrance = fragranceCost;
    if (waxCost == null ||
        fragrance == null ||
        wickCost == null ||
        vesselCost == null ||
        additionalCost == null) {
      return null;
    }
    return waxCost! + fragrance + wickCost! + vesselCost! + additionalCost!;
  }

  double? get materialCostBatch => materialCostPerContainer == null
      ? null
      : materialCostPerContainer! * containerCount;
}

class CostCalculator {
  const CostCalculator._();

  static const gramsPerPound = 453.59237;
  static const gramsPerWeightOunce = 28.349523125;
  static const millilitersPerUsFluidOunce = 29.5735295625;

  static double? positive(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  static double? nonnegative(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value >= 0 ? value : null;
  }

  static CostResult calculate({
    required double waxGrams,
    required int loadPercent,
    required List<double> shares,
    required int wickQuantity,
    required int containerCount,
    required CostAssumptions costs,
  }) {
    if (!waxGrams.isFinite ||
        waxGrams <= 0 ||
        loadPercent < 6 ||
        loadPercent > 10 ||
        wickQuantity <= 0 ||
        containerCount <= 0 ||
        CandleCalculator.parseBlendPercentages(
              shares.map((value) => '$value').toList(),
            ) ==
            null ||
        costs.fragrances.length != shares.length) {
      throw ArgumentError('Invalid candle quantities or fragrance blend.');
    }
    final gramsEach = CandleCalculator.blendAmounts(
      CandleCalculator.fragrancePerContainer(waxGrams, loadPercent),
      shares,
    );
    final missing = <String>[];
    final waxPrice = nonnegative(costs.waxPrice);
    final waxPounds = positive(costs.waxPounds);
    if (waxPrice == null) missing.add('wax purchase price');
    if (waxPounds == null) missing.add('wax package weight (lb)');
    final waxCost = waxPrice == null || waxPounds == null
        ? null
        : waxGrams * waxPrice / (waxPounds * gramsPerPound);
    final fragranceCosts = <double?>[];
    for (var index = 0; index < shares.length; index++) {
      final bottle = costs.fragrances[index];
      final price = nonnegative(bottle.price);
      final size = positive(bottle.size);
      double? bottleGrams;
      if (bottle.unit == BottleUnit.weightOz) {
        if (size != null) bottleGrams = size * gramsPerWeightOunce;
      } else {
        final net = positive(bottle.netGrams);
        final density = positive(bottle.density);
        if (net != null) {
          bottleGrams = net;
        } else if (size != null && density != null) {
          bottleGrams = size * millilitersPerUsFluidOunce * density;
        }
      }
      if (price == null) missing.add('fragrance ${index + 1} bottle price');
      if (size == null) missing.add('fragrance ${index + 1} bottle size');
      if (bottle.unit == BottleUnit.fluidOz &&
          positive(bottle.netGrams) == null &&
          positive(bottle.density) == null) {
        missing.add('fragrance ${index + 1} density or net weight');
      }
      fragranceCosts.add(
        price == null || size == null || bottleGrams == null
            ? null
            : gramsEach[index] * price / bottleGrams,
      );
    }
    final wickUnitCost = nonnegative(costs.wickUnitCost);
    final vesselCost = nonnegative(costs.vesselCost);
    final additionalCost = nonnegative(costs.additionalCost);
    if (wickUnitCost == null) missing.add('wick unit cost');
    if (vesselCost == null) missing.add('vessel cost');
    if (additionalCost == null) {
      missing.add('additional cost (enter 0 if none)');
    }
    final result = CostResult(
      waxGramsBatch: waxGrams * containerCount,
      fragranceGramsBatch: gramsEach.reduce((a, b) => a + b) * containerCount,
      fragranceGramsEach: gramsEach,
      waxCost: waxCost,
      fragranceCosts: fragranceCosts,
      wickCost: wickUnitCost == null ? null : wickUnitCost * wickQuantity,
      vesselCost: vesselCost,
      additionalCost: additionalCost,
      containerCount: containerCount,
      missing: missing,
    );
    if ([
      result.waxGramsBatch,
      result.fragranceGramsBatch,
      ...result.fragranceGramsEach,
      if (result.waxCost != null) result.waxCost!,
      ...result.fragranceCosts.whereType<double>(),
      if (result.wickCost != null) result.wickCost!,
      if (result.vesselCost != null) result.vesselCost!,
      if (result.additionalCost != null) result.additionalCost!,
      if (result.materialCostBatch != null) result.materialCostBatch!,
    ].any((value) => !value.isFinite || value >= 1e21)) {
      throw ArgumentError('Amounts are too large to calculate.');
    }
    return result;
  }
}
