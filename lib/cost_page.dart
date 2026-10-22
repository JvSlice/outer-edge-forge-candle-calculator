import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'candle_calculator.dart';
import 'cost_calculator.dart';
import 'fragrance_ratios.dart';
import 'fragrance_share_sliders.dart';
import 'recipe.dart';
import 'recipe_repository.dart';

class CostPage extends StatefulWidget {
  const CostPage({
    super.key,
    required this.repository,
    required this.initialRecipe,
    required this.initialContainers,
  });

  final RecipeRepository repository;
  final CandleRecipe initialRecipe;
  final String initialContainers;

  @override
  State<CostPage> createState() => _CostPageState();
}

class _CostPageState extends State<CostPage> {
  final _fields = <String, TextEditingController>{};
  final _names = List.generate(3, (_) => TextEditingController());
  final _shares = List.generate(3, (_) => TextEditingController());
  final _bottleFields = List.generate(
    3,
    (_) => <String, TextEditingController>{},
  );
  final _units = List.filled(3, BottleUnit.weightOz);
  List<CandleRecipe> _recipes = [];
  CandleRecipe? _loaded;
  bool _costsDirty = false;
  bool _quantitiesDirty = false;
  bool _saving = false;
  String? _message;
  int _loadPercent = 8;
  int _fragranceCount = 1;

  @override
  void initState() {
    super.initState();
    for (final key in [
      'waxType',
      'waxGrams',
      'wickQuantity',
      'containers',
      'waxPrice',
      'waxPounds',
      'wickCost',
      'vesselCost',
      'additionalCost',
    ]) {
      _fields[key] = TextEditingController();
    }
    for (final bottle in _bottleFields) {
      for (final key in ['price', 'size', 'density', 'netGrams']) {
        bottle[key] = TextEditingController();
      }
    }
    _applyRecipe(widget.initialRecipe, linked: false);
    _fields['containers']!.text = widget.initialContainers;
    _refreshRecipes();
  }

  Future<void> _refreshRecipes() async {
    try {
      final recipes = await widget.repository.load();
      if (mounted) setState(() => _recipes = recipes);
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not load recipes: $error');
    }
  }

  void _applyRecipe(CandleRecipe recipe, {required bool linked}) {
    _loaded = linked ? recipe : null;
    _fields['waxType']!.text = recipe.waxType;
    _fields['waxGrams']!.text = recipe.waxGrams;
    _fields['wickQuantity']!.text = recipe.wickQuantity;
    _loadPercent = recipe.loadPercent;
    _fragranceCount = recipe.fragrances.length;
    for (var i = 0; i < 3; i++) {
      _names[i].text = i < _fragranceCount ? recipe.fragrances[i].name : '';
      _shares[i].text = i < _fragranceCount ? recipe.fragrances[i].percent : '';
    }
    final costs =
        recipe.costs ??
        CostAssumptions(
          fragrances: List.filled(_fragranceCount, const FragranceBottle()),
        );
    _fields['waxPrice']!.text = costs.waxPrice;
    _fields['waxPounds']!.text = costs.waxPounds;
    _fields['wickCost']!.text = costs.wickUnitCost;
    _fields['vesselCost']!.text = costs.vesselCost;
    _fields['additionalCost']!.text = costs.additionalCost;
    for (var i = 0; i < 3; i++) {
      final bottle = i < costs.fragrances.length
          ? costs.fragrances[i]
          : const FragranceBottle();
      _bottleFields[i]['price']!.text = bottle.price;
      _bottleFields[i]['size']!.text = bottle.size;
      _bottleFields[i]['density']!.text = bottle.density;
      _bottleFields[i]['netGrams']!.text = bottle.netGrams;
      _units[i] = bottle.unit;
    }
    _costsDirty = false;
    _quantitiesDirty = false;
    _message = null;
  }

  void _selectRecipe(String? id) {
    if (id == null || id.isEmpty) {
      setState(() {
        _loaded = null;
        _costsDirty = false;
        _quantitiesDirty = false;
      });
      return;
    }
    for (final recipe in _recipes) {
      if (recipe.id == id) {
        setState(() => _applyRecipe(recipe, linked: true));
        return;
      }
    }
  }

  String _text(String key) => _fields[key]!.text;

  CostAssumptions get _costs => CostAssumptions(
    waxPrice: _text('waxPrice'),
    waxPounds: _text('waxPounds'),
    fragrances: [
      for (var i = 0; i < _fragranceCount; i++)
        FragranceBottle(
          price: _bottleFields[i]['price']!.text,
          size: _bottleFields[i]['size']!.text,
          unit: _units[i],
          density: _bottleFields[i]['density']!.text,
          netGrams: _bottleFields[i]['netGrams']!.text,
        ),
    ],
    wickUnitCost: _text('wickCost'),
    vesselCost: _text('vesselCost'),
    additionalCost: _text('additionalCost'),
  );

  bool get _canSaveCosts {
    final recipe = _loaded;
    if (recipe == null ||
        recipe.fragrances.length != _fragranceCount ||
        recipe.waxType != _text('waxType')) {
      return false;
    }
    for (var i = 0; i < _fragranceCount; i++) {
      if (recipe.fragrances[i].name != _names[i].text) return false;
    }
    return true;
  }

  Future<void> _saveCosts() async {
    final loaded = _loaded;
    if (!_canSaveCosts || loaded == null || _saving) return;
    setState(() => _saving = true);
    try {
      final costs = CostAssumptions.fromJson(_costs.toJson());
      final recipes = await widget.repository.load();
      final current = recipes.where((item) => item.id == loaded.id);
      if (current.isEmpty) throw const FormatException('Recipe was deleted.');
      final latest = current.single;
      if (latest.waxType != loaded.waxType ||
          latest.fragrances.length != loaded.fragrances.length ||
          List.generate(latest.fragrances.length, (i) => i).any(
            (i) => latest.fragrances[i].name != loaded.fragrances[i].name,
          )) {
        throw const FormatException(
          'Recipe changed. Reload it before saving costs.',
        );
      }
      final updated = latest.copyWith(costs: costs);
      await widget.repository.save(updated);
      if (!mounted) return;
      setState(() {
        _loaded = updated;
        _costsDirty = false;
        _message = 'Cost assumptions saved with ${updated.displayName}.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not save costs: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setCount(int count) => setState(() {
    _fragranceCount = count;
    final equal = FragranceRatios.equal(count);
    for (var i = 0; i < count; i++) {
      _shares[i].text = equal[i];
    }
    _quantitiesDirty = _loaded != null;
    _costsDirty = _loaded != null;
  });

  void _setShares(List<String> values) => setState(() {
    for (var i = 0; i < values.length; i++) {
      _shares[i].text = values[i];
    }
    _quantitiesDirty = _loaded != null;
  });

  Widget _input(String key, String label, {bool cost = false, String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          key: Key('cost-$key'),
          controller: _fields[key],
          keyboardType: key == 'waxType'
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {
            if (cost) {
              _costsDirty = _loaded != null;
            } else {
              _quantitiesDirty = _loaded != null;
            }
          }),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  Widget _bottleInput(int i, String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: Key('cost-fragrance-$i-$key'),
      controller: _bottleFields[i][key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() => _costsDirty = _loaded != null),
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _section(String title, List<Widget> children) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.copper,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );

  Widget _resultRow(String label, double? value, {String suffix = ''}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value == null
                  ? '—'
                  : suffix == ' \$'
                  ? '\$${value.toStringAsFixed(2)}'
                  : '${value.toStringAsFixed(2)}$suffix',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    for (final controller in [
      ..._fields.values,
      ..._names,
      ..._shares,
      for (final fields in _bottleFields) ...fields.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wax = CandleCalculator.parseWaxGrams(_text('waxGrams'));
    final count = CandleCalculator.parseContainerCount(_text('containers'));
    final wicks = CandleCalculator.parseContainerCount(_text('wickQuantity'));
    final shares = CandleCalculator.parseBlendPercentages([
      for (var i = 0; i < _fragranceCount; i++) _shares[i].text,
    ]);
    CostResult? result;
    String? error;
    if (wax != null && count != null && wicks != null && shares != null) {
      try {
        result = CostCalculator.calculate(
          waxGrams: wax,
          loadPercent: _loadPercent,
          shares: shares,
          wickQuantity: wicks,
          containerCount: count,
          costs: _costs,
        );
      } on ArgumentError {
        error = 'Amounts are too large to calculate.';
      }
    } else {
      error =
          'Enter positive wax grams, a positive whole-number batch and wick quantity, and blend shares totaling 100%.';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Material cost calculator')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Material cost only',
                    style: TextStyle(
                      color: AppColors.copper,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Excludes labor, taxes, selling fees, and profit.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  _section('Recipe source', [
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'cost-recipe-${_loaded?.id ?? 'standalone'}',
                      ),
                      initialValue: _loaded?.id ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Saved recipe or standalone',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Standalone calculation'),
                        ),
                        for (final recipe in _recipes)
                          DropdownMenuItem(
                            value: recipe.id,
                            child: Text(recipe.displayName),
                          ),
                      ],
                      onChanged: _selectRecipe,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loaded == null
                          ? 'Standalone calculation'
                          : 'Loaded: ${_loaded!.displayName}',
                      key: const Key('cost-loaded-recipe'),
                    ),
                    if (_loaded != null && (_costsDirty || _quantitiesDirty))
                      Text(
                        [
                          if (_costsDirty) 'Unsaved cost changes',
                          if (_quantitiesDirty) 'One-off quantity changes',
                        ].join(' · '),
                        key: const Key('cost-unsaved'),
                        style: const TextStyle(color: AppColors.copper),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save costs explicitly below. Quantity changes here do not change the saved recipe.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    if (_loaded != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('save-recipe-costs'),
                        onPressed: _canSaveCosts && !_saving
                            ? _saveCosts
                            : null,
                        child: const Text('Save costs to recipe'),
                      ),
                      if (!_canSaveCosts)
                        const Text(
                          'Restore the saved wax type and fragrance names/count before saving costs to this recipe.',
                          style: TextStyle(color: AppColors.error),
                        ),
                    ],
                    if (_message != null)
                      Text(
                        _message!,
                        style: const TextStyle(color: AppColors.copper),
                      ),
                  ]),
                  _section('Candle and batch', [
                    _input('waxType', 'Wax type / name'),
                    _input('waxGrams', 'Wax grams per container'),
                    DropdownButtonFormField<int>(
                      key: ValueKey('cost-load-$_loadPercent'),
                      initialValue: _loadPercent,
                      decoration: const InputDecoration(
                        labelText: 'Fragrance load',
                      ),
                      items: [6, 7, 8, 9, 10]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text('$item%'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _loadPercent = value ?? 8;
                        _quantitiesDirty = _loaded != null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      key: ValueKey('cost-count-$_fragranceCount'),
                      initialValue: _fragranceCount,
                      decoration: const InputDecoration(
                        labelText: 'Number of fragrances',
                      ),
                      items: [1, 2, 3]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text('$item'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) _setCount(value);
                      },
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < _fragranceCount; i++) ...[
                      TextField(
                        key: Key('cost-name-$i'),
                        controller: _names[i],
                        onChanged: (_) =>
                            setState(() => _quantitiesDirty = _loaded != null),
                        decoration: InputDecoration(
                          labelText: 'Fragrance ${i + 1} name',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FragranceShareSliders(
                      entries: [
                        for (var i = 0; i < _fragranceCount; i++)
                          _shares[i].text,
                      ],
                      keyPrefix: 'cost-share',
                      onChanged: _setShares,
                    ),
                    const SizedBox(height: 12),
                    _input('wickQuantity', 'Wicks per container'),
                    _input('containers', 'Containers in batch'),
                  ]),
                  _section('Purchase prices', [
                    _input('waxPrice', 'Wax purchase price (\$)', cost: true),
                    _input('waxPounds', 'Wax package weight (lb)', cost: true),
                    for (var i = 0; i < _fragranceCount; i++) ...[
                      const Divider(color: AppColors.border),
                      Text(
                        _names[i].text.trim().isEmpty
                            ? 'Fragrance ${i + 1}'
                            : _names[i].text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _bottleInput(i, 'price', 'Bottle price (\$)'),
                      _bottleInput(i, 'size', 'Bottle size'),
                      DropdownButtonFormField<BottleUnit>(
                        key: ValueKey('cost-unit-$i-${_units[i].name}'),
                        initialValue: _units[i],
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Bottle unit',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: BottleUnit.weightOz,
                            child: Text('oz by weight'),
                          ),
                          DropdownMenuItem(
                            value: BottleUnit.fluidOz,
                            child: Text('fl oz (US volume)'),
                          ),
                        ],
                        onChanged: (unit) => setState(() {
                          _units[i] = unit ?? BottleUnit.weightOz;
                          _costsDirty = _loaded != null;
                        }),
                      ),
                      if (_units[i] == BottleUnit.fluidOz) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Enter fragrance density or the bottle’s net weight. Fluid ounces are volume, not weight.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        _bottleInput(i, 'density', 'Density (g/mL)'),
                        _bottleInput(
                          i,
                          'netGrams',
                          'Bottle net fragrance weight (g)',
                        ),
                      ],
                    ],
                    _input('wickCost', 'Cost per wick (\$)', cost: true),
                    _input(
                      'vesselCost',
                      'Vessel cost per container (\$)',
                      cost: true,
                    ),
                    _input(
                      'additionalCost',
                      'Additional cost per container (\$)',
                      cost: true,
                    ),
                    const Text(
                      'Enter 0 for materials already on hand or no additional costs.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ]),
                  _section('Material costs per container', [
                    if (error != null)
                      Text(
                        error,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    if (result != null && result.missing.isNotEmpty)
                      Text(
                        'Missing or invalid: ${result.missing.join(', ')}.',
                        key: const Key('cost-missing'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    _resultRow('Wax', result?.waxCost, suffix: ' \$'),
                    for (var i = 0; i < _fragranceCount; i++)
                      _resultRow(
                        '${_names[i].text.trim().isEmpty ? 'Fragrance ${i + 1}' : _names[i].text.trim()} (${result?.fragranceGramsEach[i].toStringAsFixed(2) ?? '—'} g)',
                        result?.fragranceCosts[i],
                        suffix: ' \$',
                      ),
                    _resultRow(
                      'All fragrances',
                      result?.fragranceCost,
                      suffix: ' \$',
                    ),
                    _resultRow('Wicks', result?.wickCost, suffix: ' \$'),
                    _resultRow('Vessel', result?.vesselCost, suffix: ' \$'),
                    _resultRow(
                      'Additional',
                      result?.additionalCost,
                      suffix: ' \$',
                    ),
                    const Divider(color: AppColors.border),
                    _resultRow(
                      'Material cost per container',
                      result?.materialCostPerContainer,
                      suffix: ' \$',
                    ),
                  ]),
                  _section('Full batch', [
                    _resultRow(
                      'Wax needed',
                      result?.waxGramsBatch,
                      suffix: ' g',
                    ),
                    _resultRow(
                      'Fragrance needed',
                      result?.fragranceGramsBatch,
                      suffix: ' g',
                    ),
                    for (var i = 0; i < _fragranceCount; i++)
                      _resultRow(
                        '${_names[i].text.trim().isEmpty ? 'Fragrance ${i + 1}' : _names[i].text.trim()} needed',
                        result == null
                            ? null
                            : result.fragranceGramsEach[i] *
                                  result.containerCount,
                        suffix: ' g',
                      ),
                    const Divider(color: AppColors.border),
                    _resultRow(
                      'Batch wax cost',
                      result == null || result.waxCost == null
                          ? null
                          : result.waxCost! * result.containerCount,
                      suffix: ' \$',
                    ),
                    for (var i = 0; i < _fragranceCount; i++)
                      _resultRow(
                        'Fragrance ${i + 1} batch cost',
                        result == null || result.fragranceCosts[i] == null
                            ? null
                            : result.fragranceCosts[i]! * result.containerCount,
                        suffix: ' \$',
                      ),
                    _resultRow(
                      'Batch fragrance cost',
                      result == null || result.fragranceCost == null
                          ? null
                          : result.fragranceCost! * result.containerCount,
                      suffix: ' \$',
                    ),
                    _resultRow(
                      'Batch wick cost',
                      result == null || result.wickCost == null
                          ? null
                          : result.wickCost! * result.containerCount,
                      suffix: ' \$',
                    ),
                    _resultRow(
                      'Batch vessel cost',
                      result == null || result.vesselCost == null
                          ? null
                          : result.vesselCost! * result.containerCount,
                      suffix: ' \$',
                    ),
                    _resultRow(
                      'Batch additional cost',
                      result == null || result.additionalCost == null
                          ? null
                          : result.additionalCost! * result.containerCount,
                      suffix: ' \$',
                    ),
                    const Divider(color: AppColors.border),
                    _resultRow(
                      'Batch material cost',
                      result?.materialCostBatch,
                      suffix: ' \$',
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
