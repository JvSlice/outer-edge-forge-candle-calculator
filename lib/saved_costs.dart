import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cost_calculator.dart';
import 'recipe.dart';

/// A frozen candle and price snapshot; it never follows later recipe edits.
class SavedCostCalculation {
  const SavedCostCalculation({
    required this.id,
    required this.name,
    required this.recipeSnapshot,
    required this.containerCount,
    required this.createdAt,
    required this.updatedAt,
    this.linkedRecipeId,
    this.linkedRecipeName,
  });

  final String id;
  final String name;
  final CandleRecipe recipeSnapshot;
  final int containerCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedRecipeId;
  final String? linkedRecipeName;

  SavedCostCalculation copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
  }) => SavedCostCalculation(
    id: id ?? this.id,
    name: name ?? this.name,
    recipeSnapshot: recipeSnapshot,
    containerCount: containerCount,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    linkedRecipeId: linkedRecipeId,
    linkedRecipeName: linkedRecipeName,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'recipeSnapshot': recipeSnapshot.toJson(),
    'containerCount': containerCount,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'linkedRecipeId': linkedRecipeId,
    'linkedRecipeName': linkedRecipeName,
  };

  factory SavedCostCalculation.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid saved calculation.');
    }
    final map = Map<String, Object?>.from(value);
    final count = map['containerCount'];
    final created = DateTime.tryParse('${map['createdAt']}');
    final updated = DateTime.tryParse('${map['updatedAt']}');
    if (map['id'] is! String ||
        (map['id'] as String).isEmpty ||
        map['name'] is! String ||
        (map['name'] as String).trim().isEmpty ||
        count is! int ||
        count < 1 ||
        count > 1000000 ||
        created == null ||
        updated == null) {
      throw const FormatException('Invalid saved calculation fields.');
    }
    final recipe = CandleRecipe.fromJson(map['recipeSnapshot']);
    if (recipe.costs == null) {
      throw const FormatException('Cost snapshot is missing.');
    }
    return SavedCostCalculation(
      id: map['id'] as String,
      name: (map['name'] as String).trim(),
      recipeSnapshot: recipe,
      containerCount: count,
      createdAt: created,
      updatedAt: updated,
      linkedRecipeId: map['linkedRecipeId'] as String?,
      linkedRecipeName: map['linkedRecipeName'] as String?,
    );
  }
}

abstract class SavedCostStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesCostStore implements SavedCostStore {
  SharedPreferencesCostStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  @override
  Future<String?> read() =>
      _preferences.getString(SavedCostRepository.storageKey);
  @override
  Future<void> write(String value) =>
      _preferences.setString(SavedCostRepository.storageKey, value);
}

class SavedCostRepository {
  SavedCostRepository({SavedCostStore? store})
    : _store = store ?? SharedPreferencesCostStore();
  static const storageKey = 'outer_edge_forge_candle_calculator.costs.v1';
  final SavedCostStore _store;

  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<List<SavedCostCalculation>> load() async {
    final text = await _store.read();
    if (text == null) return [];
    final decoded = jsonDecode(text);
    if (decoded is! List) throw const FormatException('Invalid cost library.');
    return decoded.map(SavedCostCalculation.fromJson).toList();
  }

  Future<void> _write(List<SavedCostCalculation> records) =>
      _store.write(jsonEncode(records.map((e) => e.toJson()).toList()));

  Future<void> save(SavedCostCalculation record) async {
    SavedCostCalculation.fromJson(record.toJson());
    final records = await load();
    final index = records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      if (records.length >= 500) {
        throw const FormatException('Saved calculation limit is 500.');
      }
      records.add(record);
    } else {
      records[index] = record;
    }
    await _write(records);
  }

  Future<void> delete(String id) async {
    final records = await load()
      ..removeWhere((item) => item.id == id);
    await _write(records);
  }

  Future<String> exportJson() async => jsonEncode({
    'format': 'oef-cost-calculations-v1',
    'calculations': (await load()).map((e) => e.toJson()).toList(),
  });

  Future<int> importJson(String text) async {
    final decoded = jsonDecode(text);
    if (decoded is! Map ||
        decoded['format'] != 'oef-cost-calculations-v1' ||
        decoded['calculations'] is! List) {
      throw const FormatException(
        'This is not an OEF cost calculation backup.',
      );
    }
    final incoming = (decoded['calculations'] as List)
        .map(SavedCostCalculation.fromJson)
        .toList();
    final records = await load();
    if (records.length + incoming.length > 500) {
      throw const FormatException(
        'Import would exceed 500 saved calculations.',
      );
    }
    final ids = records.map((e) => e.id).toSet();
    final names = records.map((e) => e.name.toLowerCase()).toSet();
    for (final record in incoming) {
      final copy = record.copyWith(id: newId());
      var name = copy.name;
      var suffix = 1;
      while (names.contains(name.toLowerCase())) {
        name = '${copy.name} (imported ${suffix++})';
      }
      final safeCopy = SavedCostCalculation(
        id: copy.id,
        name: name,
        recipeSnapshot: copy.recipeSnapshot,
        containerCount: copy.containerCount,
        createdAt: copy.createdAt,
        updatedAt: DateTime.now().toUtc(),
        linkedRecipeId: copy.linkedRecipeId,
        linkedRecipeName: copy.linkedRecipeName,
      );
      if (ids.add(safeCopy.id)) records.add(safeCopy);
      names.add(name.toLowerCase());
    }
    await _write(records);
    return incoming.length;
  }
}

String costCalculationsCsv(List<SavedCostCalculation> records) {
  String q(Object? value) => '"${'${value ?? ''}'.replaceAll('"', '""')}"';
  final rows = <List<Object?>>[
    [
      'Calculation name',
      'Linked recipe',
      'Saved date',
      'Updated date',
      'Batch containers',
      'Wax type',
      'Wax g/container',
      'Fragrance load %',
      'Fragrance names',
      'Fragrance shares %',
      'Wick quantity/container',
      'Wax price USD',
      'Wax package lb',
      'Fragrance bottle prices USD',
      'Fragrance bottle sizes',
      'Fragrance units',
      'Fragrance densities g/mL',
      'Fragrance net weights g',
      'Wick cost USD/each',
      'Vessel cost USD/container',
      'Additional cost USD/container',
      'Wax cost USD/container',
      'Fragrance cost USD/container',
      'Wick cost USD/container',
      'Vessel cost USD/container',
      'Additional cost USD/container',
      'Material total USD/container',
      'Wax cost USD/batch',
      'Fragrance cost USD/batch',
      'Material total USD/batch',
      'Status',
    ],
    for (final record in records) _csvCostRow(record),
  ];
  return rows.map((row) => row.map(q).join(',')).join('\r\n');
}

List<Object?> _csvCostRow(SavedCostCalculation record) {
  final r = record.recipeSnapshot;
  final costs = r.costs!;
  final shares = r.fragrances
      .map((f) => double.tryParse(f.percent) ?? 0)
      .toList();
  final result = CostCalculator.calculate(
    waxGrams: double.parse(r.waxGrams),
    loadPercent: r.loadPercent,
    shares: shares,
    wickQuantity: int.parse(r.wickQuantity),
    containerCount: record.containerCount,
    costs: costs,
  );
  String? money(double? value) =>
      value == null ? null : CostCalculator.currencyUp(value);
  return [
    record.name,
    record.linkedRecipeName,
    record.createdAt.toIso8601String(),
    record.updatedAt.toIso8601String(),
    record.containerCount,
    r.waxType,
    r.waxGrams,
    r.loadPercent,
    r.fragrances.map((f) => f.name).join(' | '),
    r.fragrances.map((f) => f.percent).join(' | '),
    r.wickQuantity,
    costs.waxPrice,
    costs.waxPounds,
    costs.fragrances.map((f) => f.price).join(' | '),
    costs.fragrances.map((f) => f.size).join(' | '),
    costs.fragrances.map((f) => f.unit.name).join(' | '),
    costs.fragrances.map((f) => f.density).join(' | '),
    costs.fragrances.map((f) => f.netGrams).join(' | '),
    costs.wickUnitCost,
    costs.vesselCost,
    costs.additionalCost,
    money(result.waxCost),
    money(result.fragranceCost),
    money(result.wickCost),
    money(result.vesselCost),
    money(result.additionalCost),
    money(result.materialCostPerContainer),
    money(
      result.waxCost == null ? null : result.waxCost! * record.containerCount,
    ),
    money(
      result.fragranceCost == null
          ? null
          : result.fragranceCost! * record.containerCount,
    ),
    money(result.materialCostBatch),
    result.missing.isEmpty
        ? 'Complete'
        : 'Incomplete: ${result.missing.join('; ')}',
  ];
}
