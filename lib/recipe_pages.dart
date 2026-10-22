import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import 'app_colors.dart';
import 'candle_calculator.dart';
import 'fragrance_ratios.dart';
import 'fragrance_share_sliders.dart';
import 'recipe.dart';
import 'recipe_file_io.dart';
import 'recipe_pdf_actions.dart';
import 'recipe_pdf_document.dart';
import 'recipe_repository.dart';

class RecipeLibraryPage extends StatefulWidget {
  const RecipeLibraryPage({
    super.key,
    required this.repository,
    required this.newRecipeTemplate,
  });

  final RecipeRepository repository;
  final CandleRecipe newRecipeTemplate;

  @override
  State<RecipeLibraryPage> createState() => _RecipeLibraryPageState();
}

class _RecipeLibraryPageState extends State<RecipeLibraryPage> {
  late Future<List<CandleRecipe>> _recipes;
  final Set<String> _selectedRecipeIds = {};

  @override
  void initState() {
    super.initState();
    _recipes = widget.repository.load();
  }

  void _refresh() {
    final next = widget.repository.load();
    setState(() {
      _recipes = next;
    });
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit(CandleRecipe recipe) async {
    await Navigator.of(context).push<CandleRecipe>(
      MaterialPageRoute(
        builder: (_) =>
            RecipeEditorPage(repository: widget.repository, recipe: recipe),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _duplicate(CandleRecipe recipe) async {
    try {
      await widget.repository.duplicate(recipe);
      if (!mounted) return;
      _refresh();
      _message('Recipe duplicated.');
    } catch (error) {
      if (mounted) _message('Could not duplicate recipe: $error');
    }
  }

  Future<void> _delete(CandleRecipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Delete “${recipe.displayName}” from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.delete(recipe.id);
      if (!mounted) return;
      _selectedRecipeIds.remove(recipe.id);
      _refresh();
      _message('Recipe deleted.');
    } catch (error) {
      if (mounted) _message('Could not delete recipe: $error');
    }
  }

  Future<void> _export() async {
    try {
      RecipeFileIo.downloadJson(await widget.repository.exportJson());
      if (mounted) _message('JSON backup download started.');
    } catch (error) {
      if (mounted) _message('Could not export recipes: $error');
    }
  }

  Future<void> _import() async {
    try {
      final text = await RecipeFileIo.pickJson();
      if (text == null || !mounted) return;
      final plan = await widget.repository.inspectImport(text);
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import recipes?'),
          content: Text(
            '${plan.count} recipe${plan.count == 1 ? '' : 's'} found. '
            '${plan.duplicateCount} match an existing name or ID. '
            'Every imported recipe will be added as a copy. Existing recipes will not be overwritten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Import as copies'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      final count = await widget.repository.importAsCopies(plan);
      if (!mounted) return;
      _refresh();
      _message('Imported $count recipe${count == 1 ? '' : 's'} as copies.');
    } catch (error) {
      if (mounted) _message('Could not import backup: $error');
    }
  }

  Future<int?> _askBatchCount() async {
    return showDialog<int>(
      context: context,
      builder: (_) => const _BatchQuantityDialog(),
    );
  }

  String _pdfFileName(List<CandleRecipe> recipes) {
    final stem = (recipes.length == 1 ? recipes.single.displayName : 'recipes')
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'oef-candle-${stem.isEmpty ? 'recipes' : stem}-printout.pdf';
  }

  Future<void> _makePdf(
    List<CandleRecipe> recipes, {
    required bool print,
  }) async {
    if (recipes.isEmpty) return;
    final batchCount = await _askBatchCount();
    if (batchCount == null || !mounted) return;
    try {
      final bytes = await RecipePdfDocument.build(
        recipes: recipes,
        batchCount: batchCount,
      );
      if (!mounted) return;
      final fileName = _pdfFileName(recipes);
      if (kIsWeb) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => RecipePdfActionsPage(
              bytes: bytes,
              fileName: fileName,
              recipeCount: recipes.length,
              batchCount: batchCount,
            ),
          ),
        );
      } else if (print) {
        await Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes);
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: fileName,
          subject: 'OEF candle recipe printout',
        );
      }
    } catch (error) {
      if (mounted) _message('Could not create the PDF printout: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saved recipes')),
    body: SafeArea(
      child: FutureBuilder<List<CandleRecipe>>(
        future: _recipes,
        builder: (context, snapshot) {
          final recipes = snapshot.data ?? [];
          final selectedRecipes = recipes
              .where((recipe) => _selectedRecipeIds.contains(recipe.id))
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Recipes are saved in this browser on this device. Export a JSON backup before clearing browser data or moving devices.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const Key('create-recipe'),
                    onPressed: () => _edit(
                      widget.newRecipeTemplate.copyWith(
                        id: widget.repository.newId(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create recipe'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('export-recipes'),
                    onPressed: _export,
                    icon: const Icon(Icons.download),
                    label: const Text('Export JSON'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('import-recipes'),
                    onPressed: _import,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import JSON'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('export-selected-pdf'),
                    onPressed: selectedRecipes.isEmpty
                        ? null
                        : () => _makePdf(selectedRecipes, print: false),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text('PDF printout (${selectedRecipes.length})'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('print-selected-pdf'),
                    onPressed: selectedRecipes.isEmpty
                        ? null
                        : () => _makePdf(selectedRecipes, print: true),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print selected'),
                  ),
                ],
              ),
              if (recipes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      key: const Key('toggle-select-all-recipes'),
                      onPressed: () => setState(() {
                        if (_selectedRecipeIds.length == recipes.length) {
                          _selectedRecipeIds.clear();
                        } else {
                          _selectedRecipeIds
                            ..clear()
                            ..addAll(recipes.map((recipe) => recipe.id));
                        }
                      }),
                      child: Text(
                        _selectedRecipeIds.length == recipes.length
                            ? 'Clear selection'
                            : 'Select all',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedRecipes.length} selected',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const Text(
                  'PDF printouts are for printing and reference. Export JSON for editable backups.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              if (snapshot.hasError)
                Text(
                  'Could not read saved recipes: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                )
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (recipes.isEmpty)
                const Text(
                  'No recipes saved yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                for (final recipe in recipes) ...[
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                key: Key('select-${recipe.id}'),
                                semanticLabel:
                                    'Select ${recipe.displayName} for PDF printout',
                                value: _selectedRecipeIds.contains(recipe.id),
                                onChanged: (selected) => setState(() {
                                  if (selected == true) {
                                    _selectedRecipeIds.add(recipe.id);
                                  } else {
                                    _selectedRecipeIds.remove(recipe.id);
                                  }
                                }),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recipe.displayName,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            [
                              if (recipe.containerName.trim().isNotEmpty)
                                recipe.containerName.trim(),
                              if (recipe.containerSize.trim().isNotEmpty)
                                '${recipe.containerSize.trim()} ${recipe.containerUnit}',
                              if (recipe.waxType.trim().isNotEmpty)
                                recipe.waxType.trim(),
                            ].join(' · '),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              FilledButton(
                                key: Key('load-${recipe.id}'),
                                onPressed: () => Navigator.pop(context, recipe),
                                child: const Text('Load'),
                              ),
                              TextButton(
                                key: Key('edit-${recipe.id}'),
                                onPressed: () => _edit(recipe),
                                child: const Text('Edit'),
                              ),
                              TextButton(
                                key: Key('duplicate-${recipe.id}'),
                                onPressed: () => _duplicate(recipe),
                                child: const Text('Duplicate'),
                              ),
                              TextButton(
                                key: Key('delete-${recipe.id}'),
                                onPressed: () => _delete(recipe),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    ),
  );
}

class RecipeEditorPage extends StatefulWidget {
  const RecipeEditorPage({
    super.key,
    required this.repository,
    required this.recipe,
    this.requireUsableFormula = false,
  });

  final RecipeRepository repository;
  final CandleRecipe recipe;
  final bool requireUsableFormula;

  @override
  State<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends State<RecipeEditorPage> {
  late final Map<String, TextEditingController> _fields;
  late final List<TextEditingController> _fragranceNames;
  late final List<TextEditingController> _fragrancePercents;
  late int _fragranceCount;
  late int _loadPercent;
  late String _containerUnit;
  late String _spacingUnit;
  late String _temperatureUnit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _fields = {
      'name': TextEditingController(text: recipe.name),
      'containerName': TextEditingController(text: recipe.containerName),
      'containerSize': TextEditingController(text: recipe.containerSize),
      'waxType': TextEditingController(text: recipe.waxType),
      'waxGrams': TextEditingController(text: recipe.waxGrams),
      'wickQuantity': TextEditingController(text: recipe.wickQuantity),
      'wickSeries': TextEditingController(text: recipe.wickSeries),
      'wickSize': TextEditingController(text: recipe.wickSize),
      'wickSpacing': TextEditingController(text: recipe.wickSpacing),
      'wickArrangement': TextEditingController(text: recipe.wickArrangement),
      'fragranceTemperature': TextEditingController(
        text: recipe.fragranceTemperature,
      ),
      'pourTemperature': TextEditingController(text: recipe.pourTemperature),
      'notes': TextEditingController(text: recipe.notes),
    };
    _fragranceNames = List.generate(
      3,
      (index) => TextEditingController(
        text: index < recipe.fragrances.length
            ? recipe.fragrances[index].name
            : '',
      ),
    );
    _fragrancePercents = List.generate(
      3,
      (index) => TextEditingController(
        text: index < recipe.fragrances.length
            ? recipe.fragrances[index].percent
            : '',
      ),
    );
    _fragranceCount = recipe.fragrances.length;
    _loadPercent = recipe.loadPercent;
    _containerUnit = recipe.containerUnit;
    _spacingUnit = recipe.wickSpacingUnit;
    _temperatureUnit = recipe.temperatureUnit;
  }

  @override
  void dispose() {
    for (final controller in [
      ..._fields.values,
      ..._fragranceNames,
      ..._fragrancePercents,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _fields[key]!.text;

  Widget _field(
    String key,
    String label, {
    bool number = false,
    int lines = 1,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      key: Key('recipe-$key'),
      controller: _fields[key],
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, helperText: helper),
    ),
  );

  Widget _unitDropdown(
    String label,
    String value,
    List<String> units,
    ValueChanged<String> onChanged, {
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: units
          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) setState(() => onChanged(selected));
      },
    ),
  );

  void _setCount(int count) {
    setState(() {
      _fragranceCount = count;
      final values = FragranceRatios.equal(count);
      for (var index = 0; index < count; index++) {
        _fragrancePercents[index].text = values[index];
      }
    });
  }

  void _setFragranceShares(List<String> shares) => setState(() {
    for (var index = 0; index < shares.length; index++) {
      _fragrancePercents[index].text = shares[index];
    }
  });

  Future<void> _save() async {
    if (_saving) return;
    if (widget.requireUsableFormula) {
      final name = _text('name').trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a recipe name before saving.')),
        );
        return;
      }
      if (CandleCalculator.parseWaxGrams(_text('waxGrams')) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a wax weight greater than zero before saving a recipe.',
            ),
          ),
        );
        return;
      }
      if (CandleCalculator.parseBlendPercentages([
            for (var index = 0; index < _fragranceCount; index++)
              _fragrancePercents[index].text,
          ]) ==
          null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set valid fragrance shares totaling 100% before saving a recipe.',
            ),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final fragrances = List.generate(
      _fragranceCount,
      (index) => FragrancePart(
        name: _fragranceNames[index].text,
        percent: _fragrancePercents[index].text,
      ),
    );
    try {
      final stored = await widget.repository.load();
      final matches = stored.where((item) => item.id == widget.recipe.id);
      final base = matches.isEmpty ? widget.recipe : matches.single;
      final recipe = base.copyWith(
        name: _text('name'),
        containerName: _text('containerName'),
        containerSize: _text('containerSize'),
        containerUnit: _containerUnit,
        waxType: _text('waxType'),
        waxGrams: _text('waxGrams'),
        loadPercent: _loadPercent,
        fragrances: fragrances,
        costs: base.costs?.alignedToNames(
          base.fragrances.map((part) => part.name).toList(),
          fragrances.map((part) => part.name).toList(),
        ),
        wickQuantity: _text('wickQuantity'),
        wickSeries: _text('wickSeries'),
        wickSize: _text('wickSize'),
        wickSpacing: _text('wickSpacing'),
        wickSpacingUnit: _spacingUnit,
        wickArrangement: _text('wickArrangement'),
        fragranceTemperature: _text('fragranceTemperature'),
        pourTemperature: _text('pourTemperature'),
        temperatureUnit: _temperatureUnit,
        notes: _text('notes'),
      );
      await widget.repository.save(recipe);
      if (mounted) Navigator.pop(context, recipe);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save recipe: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recipe details')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save a draft at any time. Wax weight and blend shares must be valid before the calculator shows results.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 22),
                _heading('Candle and container'),
                _field('name', 'Recipe / candle name'),
                _field('containerName', 'Container type / name'),
                _field('containerSize', 'Container size', number: true),
                _unitDropdown(
                  'Container size unit',
                  _containerUnit,
                  CandleRecipe.containerUnits,
                  (value) => _containerUnit = value,
                ),
                _heading('Wax and fragrances'),
                _field('waxType', 'Wax type / name'),
                _field(
                  'waxGrams',
                  'Wax weight per container (g)',
                  number: true,
                  helper: 'Wax alone, before fragrance.',
                ),
                _unitDropdown(
                  'Fragrance load',
                  '$_loadPercent%',
                  [6, 7, 8, 9, 10].map((value) => '$value%').toList(),
                  (value) =>
                      _loadPercent = int.parse(value.replaceAll('%', '')),
                  key: const Key('recipe-load-percent'),
                ),
                DropdownButtonFormField<int>(
                  key: const Key('recipe-fragrance-count'),
                  initialValue: _fragranceCount,
                  decoration: const InputDecoration(
                    labelText: 'Number of fragrances',
                  ),
                  items: [1, 2, 3]
                      .map(
                        (count) => DropdownMenuItem(
                          value: count,
                          child: Text('$count'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _setCount(value);
                  },
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < _fragranceCount; index++) ...[
                  TextField(
                    key: Key('recipe-fragrance-name-$index'),
                    controller: _fragranceNames[index],
                    decoration: InputDecoration(
                      labelText: 'Fragrance ${index + 1} name',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FragranceShareSliders(
                  entries: [
                    for (var index = 0; index < _fragranceCount; index++)
                      _fragrancePercents[index].text,
                  ],
                  keyPrefix: 'recipe-fragrance-slider',
                  onChanged: _setFragranceShares,
                ),
                _heading('Wicks'),
                _field('wickQuantity', 'Wick quantity', number: true),
                _field('wickSeries', 'Wick series / type'),
                _field('wickSize', 'Wick size'),
                _field('wickSpacing', 'Center-to-center spacing', number: true),
                _unitDropdown(
                  'Spacing unit',
                  _spacingUnit,
                  CandleRecipe.spacingUnits,
                  (value) => _spacingUnit = value,
                ),
                _field(
                  'wickArrangement',
                  'Wick arrangement',
                  helper: 'Describe the layout for three or more wicks.',
                ),
                _heading('Temperatures and notes'),
                _unitDropdown(
                  'Temperature unit',
                  _temperatureUnit,
                  CandleRecipe.temperatureUnits,
                  (value) => _temperatureUnit = value,
                ),
                _field(
                  'fragranceTemperature',
                  'Fragrance addition temperature',
                  number: true,
                ),
                _field('pourTemperature', 'Pour temperature', number: true),
                _field('notes', 'Notes', lines: 4),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    key: const Key('save-recipe'),
                    onPressed: _saving ? null : _save,
                    child: const Text('Save recipe'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.copper,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _BatchQuantityDialog extends StatefulWidget {
  const _BatchQuantityDialog();

  @override
  State<_BatchQuantityDialog> createState() => _BatchQuantityDialogState();
}

class _BatchQuantityDialogState extends State<_BatchQuantityDialog> {
  final _controller = TextEditingController(text: '1');
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final count = int.tryParse(_controller.text.trim());
    if (count == null || count <= 0) {
      setState(() => _errorText = 'Enter a positive whole number.');
      return;
    }
    Navigator.pop(context, count);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Batch quantity'),
    content: TextField(
      key: const Key('pdf-batch-count'),
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Containers per recipe',
        errorText: _errorText,
      ),
      onChanged: (_) {
        if (_errorText != null) setState(() => _errorText = null);
      },
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirm-pdf-batch'),
        onPressed: _continue,
        child: const Text('Continue'),
      ),
    ],
  );
}
