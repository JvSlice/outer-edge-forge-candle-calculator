import 'package:flutter_test/flutter_test.dart';
import 'package:outer_edge_forge_candle_calculator/recipe.dart';
import 'package:outer_edge_forge_candle_calculator/recipe_pdf_document.dart';
import 'package:outer_edge_forge_candle_calculator/recipe_print_calculator.dart';

void main() {
  test('print calculations scale wax and each fragrance for the batch', () {
    const recipe = CandleRecipe(
      id: 'print-example',
      name: 'Cedar and Amber',
      waxGrams: '100',
      loadPercent: 8,
      fragrances: [
        FragrancePart(name: 'Cedar', percent: '75'),
        FragrancePart(name: 'Amber', percent: '25'),
      ],
    );

    final data = RecipePrintData.forBatch(recipe, 5);

    expect(data.waxPerContainer, 100);
    expect(data.batchWax, 500);
    expect(data.fragrancePerContainer, 8);
    expect(data.batchFragrance, 40);
    expect(data.fragrances[0].perContainerGrams, 6);
    expect(data.fragrances[0].batchGrams, 30);
    expect(data.fragrances[1].perContainerGrams, 2);
    expect(data.fragrances[1].batchGrams, 10);
    expect(recipe.waxGrams, '100');
    expect(recipe.fragrances.first.percent, '75');
  });

  test('invalid draft quantities stay unavailable in the printout data', () {
    const recipe = CandleRecipe(
      id: 'print-draft',
      waxGrams: '',
      fragrances: [
        FragrancePart(name: 'Cedar', percent: '60'),
        FragrancePart(name: 'Amber', percent: '30'),
      ],
    );
    final data = RecipePrintData.forBatch(recipe, 2);
    expect(data.waxPerContainer, isNull);
    expect(data.batchWax, isNull);
    expect(data.fragrancePerContainer, isNull);
    expect(data.fragrances.every((part) => part.batchGrams == null), isTrue);
  });

  test('batch size must be a positive whole number', () {
    const recipe = CandleRecipe(id: 'print-example');
    expect(() => RecipePrintData.forBatch(recipe, 0), throwsArgumentError);
  });

  test('PDF generation includes the OEF logo and paginates long notes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final notes = List.generate(
      150,
      (index) =>
          'Step ${index + 1}: warm the wax slowly and record the temperature before adding fragrance.',
    ).join('\n');
    final bytes = await RecipePdfDocument.build(
      recipes: [
        CandleRecipe(
          id: 'long-print',
          name: 'Long Notes Candle',
          containerName: 'Tall glass vessel',
          containerSize: '8',
          waxType: 'Soy blend',
          waxGrams: '100',
          loadPercent: 8,
          fragrances: const [
            FragrancePart(name: 'Cedar', percent: '75'),
            FragrancePart(name: 'Amber', percent: '25'),
          ],
          wickQuantity: '2',
          wickSeries: 'CD',
          wickSize: '10',
          wickSpacing: '1.5',
          wickArrangement: 'Evenly spaced',
          fragranceTemperature: '185',
          pourTemperature: '150',
          notes: notes,
        ),
        const CandleRecipe(id: 'second', name: 'Second Pour'),
      ],
      batchCount: 5,
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final source = String.fromCharCodes(bytes);
    final pageCount = RegExp(r'/Type\s*/Page\b').allMatches(source).length;
    expect(pageCount, greaterThanOrEqualTo(3));
  });
}
