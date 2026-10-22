import 'dart:convert';

class FragrancePart {
  const FragrancePart({this.name = '', this.percent = '100'});

  final String name;
  final String percent;

  FragrancePart copyWith({String? name, String? percent}) =>
      FragrancePart(name: name ?? this.name, percent: percent ?? this.percent);

  Map<String, Object> toJson() => {'name': name, 'percent': percent};

  factory FragrancePart.fromJson(Object? value) {
    final map = _object(value);
    final percent = _string(map, 'percent', 40);
    _optionalPositiveDouble(percent, 'Fragrance share', maximum: 100);
    return FragrancePart(name: _string(map, 'name', 200), percent: percent);
  }
}

/// Raw numeric text is retained so incomplete recipes can be saved as drafts.
class CandleRecipe {
  const CandleRecipe({
    required this.id,
    this.name = '',
    this.containerName = '',
    this.containerSize = '',
    this.containerUnit = 'oz',
    this.waxType = '',
    this.waxGrams = '',
    this.loadPercent = 8,
    this.fragrances = const [FragrancePart()],
    this.wickQuantity = '',
    this.wickSeries = '',
    this.wickSize = '',
    this.wickSpacing = '',
    this.wickSpacingUnit = 'in',
    this.wickArrangement = '',
    this.fragranceTemperature = '',
    this.pourTemperature = '',
    this.temperatureUnit = '°F',
    this.notes = '',
  });

  static const containerUnits = ['oz', 'mL', 'L', 'g', 'fl oz'];
  static const spacingUnits = ['in', 'cm', 'mm'];
  static const temperatureUnits = ['°F', '°C'];

  final String id;
  final String name;
  final String containerName;
  final String containerSize;
  final String containerUnit;
  final String waxType;
  final String waxGrams;
  final int loadPercent;
  final List<FragrancePart> fragrances;
  final String wickQuantity;
  final String wickSeries;
  final String wickSize;
  final String wickSpacing;
  final String wickSpacingUnit;
  final String wickArrangement;
  final String fragranceTemperature;
  final String pourTemperature;
  final String temperatureUnit;
  final String notes;

  String get displayName =>
      name.trim().isEmpty ? 'Untitled recipe' : name.trim();

  CandleRecipe copyWith({
    String? id,
    String? name,
    String? containerName,
    String? containerSize,
    String? containerUnit,
    String? waxType,
    String? waxGrams,
    int? loadPercent,
    List<FragrancePart>? fragrances,
    String? wickQuantity,
    String? wickSeries,
    String? wickSize,
    String? wickSpacing,
    String? wickSpacingUnit,
    String? wickArrangement,
    String? fragranceTemperature,
    String? pourTemperature,
    String? temperatureUnit,
    String? notes,
  }) => CandleRecipe(
    id: id ?? this.id,
    name: name ?? this.name,
    containerName: containerName ?? this.containerName,
    containerSize: containerSize ?? this.containerSize,
    containerUnit: containerUnit ?? this.containerUnit,
    waxType: waxType ?? this.waxType,
    waxGrams: waxGrams ?? this.waxGrams,
    loadPercent: loadPercent ?? this.loadPercent,
    fragrances: fragrances ?? this.fragrances,
    wickQuantity: wickQuantity ?? this.wickQuantity,
    wickSeries: wickSeries ?? this.wickSeries,
    wickSize: wickSize ?? this.wickSize,
    wickSpacing: wickSpacing ?? this.wickSpacing,
    wickSpacingUnit: wickSpacingUnit ?? this.wickSpacingUnit,
    wickArrangement: wickArrangement ?? this.wickArrangement,
    fragranceTemperature: fragranceTemperature ?? this.fragranceTemperature,
    pourTemperature: pourTemperature ?? this.pourTemperature,
    temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    notes: notes ?? this.notes,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'containerName': containerName,
    'containerSize': containerSize,
    'containerUnit': containerUnit,
    'waxType': waxType,
    'waxGrams': waxGrams,
    'loadPercent': loadPercent,
    'fragrances': fragrances.map((part) => part.toJson()).toList(),
    'wickQuantity': wickQuantity,
    'wickSeries': wickSeries,
    'wickSize': wickSize,
    'wickSpacing': wickSpacing,
    'wickSpacingUnit': wickSpacingUnit,
    'wickArrangement': wickArrangement,
    'fragranceTemperature': fragranceTemperature,
    'pourTemperature': pourTemperature,
    'temperatureUnit': temperatureUnit,
    'notes': notes,
  };

  factory CandleRecipe.fromJson(Object? value) {
    final map = _object(value);
    final id = _string(map, 'id', 128);
    if (id.trim().isEmpty) throw const FormatException('Recipe ID is empty.');
    final load = map['loadPercent'];
    if (load is! int || load < 6 || load > 10) {
      throw const FormatException('Fragrance load must be 6–10%.');
    }
    final rawParts = map['fragrances'];
    if (rawParts is! List || rawParts.isEmpty || rawParts.length > 3) {
      throw const FormatException('A recipe needs 1–3 fragrances.');
    }
    final containerUnit = _string(map, 'containerUnit', 12);
    final spacingUnit = _string(map, 'wickSpacingUnit', 12);
    final temperatureUnit = _string(map, 'temperatureUnit', 12);
    if (!containerUnits.contains(containerUnit) ||
        !spacingUnits.contains(spacingUnit) ||
        !temperatureUnits.contains(temperatureUnit)) {
      throw const FormatException('A recipe has an unsupported unit.');
    }
    final containerSize = _string(map, 'containerSize', 40);
    final waxGrams = _string(map, 'waxGrams', 40);
    final wickQuantity = _string(map, 'wickQuantity', 40);
    final wickSpacing = _string(map, 'wickSpacing', 40);
    final fragranceTemperature = _string(map, 'fragranceTemperature', 40);
    final pourTemperature = _string(map, 'pourTemperature', 40);
    _optionalPositiveDouble(containerSize, 'Container size');
    _optionalPositiveDouble(waxGrams, 'Wax weight');
    _optionalPositiveInt(wickQuantity, 'Wick quantity');
    _optionalPositiveDouble(wickSpacing, 'Wick spacing');
    _optionalFiniteDouble(
      fragranceTemperature,
      'Fragrance addition temperature',
    );
    _optionalFiniteDouble(pourTemperature, 'Pour temperature');
    return CandleRecipe(
      id: id,
      name: _string(map, 'name', 200),
      containerName: _string(map, 'containerName', 200),
      containerSize: containerSize,
      containerUnit: containerUnit,
      waxType: _string(map, 'waxType', 200),
      waxGrams: waxGrams,
      loadPercent: load,
      fragrances: rawParts.map(FragrancePart.fromJson).toList(),
      wickQuantity: wickQuantity,
      wickSeries: _string(map, 'wickSeries', 200),
      wickSize: _string(map, 'wickSize', 100),
      wickSpacing: wickSpacing,
      wickSpacingUnit: spacingUnit,
      wickArrangement: _string(map, 'wickArrangement', 500),
      fragranceTemperature: fragranceTemperature,
      pourTemperature: pourTemperature,
      temperatureUnit: temperatureUnit,
      notes: _string(map, 'notes', 4000),
    );
  }
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  if (value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected string keys.');
  }
  return Map<String, Object?>.from(value);
}

String _string(Map<String, Object?> map, String key, int maxLength) {
  final value = map[key];
  if (value is! String || value.length > maxLength) {
    throw FormatException('Invalid recipe field: $key.');
  }
  return value;
}

void _optionalPositiveDouble(String text, String label, {double? maximum}) {
  if (text.trim().isEmpty) return;
  final value = double.tryParse(text.trim());
  if (value == null ||
      !value.isFinite ||
      value <= 0 ||
      (maximum != null && value > maximum)) {
    throw FormatException('$label must be a positive number.');
  }
}

void _optionalPositiveInt(String text, String label) {
  if (text.trim().isEmpty) return;
  final value = int.tryParse(text.trim());
  if (value == null || value <= 0) {
    throw FormatException('$label must be a positive whole number.');
  }
}

void _optionalFiniteDouble(String text, String label) {
  if (text.trim().isEmpty) return;
  final value = double.tryParse(text.trim());
  if (value == null || !value.isFinite) {
    throw FormatException('$label must be a number.');
  }
}

class RecipeBackup {
  const RecipeBackup(this.recipes);

  final List<CandleRecipe> recipes;

  String toJsonString() => const JsonEncoder.withIndent('  ').convert({
    'format': 'oef-candle-recipes',
    'version': 1,
    'recipes': recipes.map((recipe) => recipe.toJson()).toList(),
  });

  factory RecipeBackup.parse(String text) {
    if (text.length > 5 * 1024 * 1024) {
      throw const FormatException('Backup is too large (5 MB maximum).');
    }
    final Map<String, Object?> map;
    try {
      map = _object(jsonDecode(text));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('This is not valid JSON.');
    }
    if (map['format'] != 'oef-candle-recipes' || map['version'] != 1) {
      throw const FormatException('Unsupported recipe backup format.');
    }
    final rawRecipes = map['recipes'];
    if (rawRecipes is! List || rawRecipes.length > 500) {
      throw const FormatException('Backup must contain at most 500 recipes.');
    }
    final recipes = rawRecipes.map(CandleRecipe.fromJson).toList();
    final ids = recipes.map((recipe) => recipe.id).toSet();
    if (ids.length != recipes.length) {
      throw const FormatException('Backup contains duplicate recipe IDs.');
    }
    return RecipeBackup(recipes);
  }
}
