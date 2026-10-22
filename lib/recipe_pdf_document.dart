import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'recipe.dart';
import 'recipe_print_calculator.dart';

class RecipePdfDocument {
  const RecipePdfDocument._();

  static Future<Uint8List> build({
    required List<CandleRecipe> recipes,
    required int batchCount,
  }) async {
    if (recipes.isEmpty) throw ArgumentError('Select at least one recipe.');
    final printData = recipes
        .map((recipe) => RecipePrintData.forBatch(recipe, batchCount))
        .toList();
    final logoData = await rootBundle.load(
      'assets/branding/oef-icon-original.png',
    );
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
    final document = pw.Document(
      title: 'Outer Edge Forge candle recipe printout',
      author: 'Outer Edge Forge',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 38, 38, 48),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Text(
            'OEF recipe printout  -  Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
          ),
        ),
        build: (context) => [
          for (var index = 0; index < printData.length; index++) ...[
            if (index > 0) pw.NewPage(),
            ..._recipeWidgets(printData[index], logo),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await document.save());
  }

  static List<pw.Widget> _recipeWidgets(
    RecipePrintData data,
    pw.ImageProvider logo,
  ) {
    final recipe = data.recipe;
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(width: 42, height: 42, child: pw.Image(logo)),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'OUTER EDGE FORGE',
                  style: pw.TextStyle(
                    color: PdfColors.brown700,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Candle Recipe',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: PdfColors.brown400, thickness: 1.4),
      pw.SizedBox(height: 8),
      pw.Text(
        recipe.displayName,
        style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        'Batch quantity: ${data.batchCount} containers',
        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
      ),
      pw.SizedBox(height: 16),
      _section('Container and wax'),
      _field('Container type / name', _value(recipe.containerName)),
      _field(
        'Container size',
        recipe.containerSize.trim().isEmpty
            ? 'Not specified'
            : '${recipe.containerSize.trim()} ${recipe.containerUnit}',
      ),
      _field('Wax type', _value(recipe.waxType)),
      _field('Wax per container', '${_grams(data.waxPerContainer)} g'),
      _field('Batch wax', '${_grams(data.batchWax)} g'),
      _field('Fragrance load', '${recipe.loadPercent}%'),
      _field(
        'Fragrance per container',
        '${_grams(data.fragrancePerContainer)} g',
      ),
      _field('Batch fragrance total', '${_grams(data.batchFragrance)} g'),
      pw.SizedBox(height: 14),
      _section('Fragrance blend'),
      _fragranceHeader(),
      for (final fragrance in data.fragrances) _fragranceRow(fragrance),
      pw.SizedBox(height: 14),
      _section('Wicks'),
      _field('Wick quantity', _value(recipe.wickQuantity)),
      _field('Wick series / type', _value(recipe.wickSeries)),
      _field('Wick size', _value(recipe.wickSize)),
      _field(
        'Center-to-center spacing',
        recipe.wickSpacing.trim().isEmpty
            ? 'Not specified'
            : '${recipe.wickSpacing.trim()} ${recipe.wickSpacingUnit}',
      ),
      _field('Wick arrangement', _value(recipe.wickArrangement)),
      pw.SizedBox(height: 14),
      _section('Temperatures and notes'),
      _field(
        'Fragrance addition temperature (${recipe.temperatureUnit})',
        _value(recipe.fragranceTemperature),
      ),
      _field(
        'Pour temperature (${recipe.temperatureUnit})',
        _value(recipe.pourTemperature),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Notes',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 3),
      pw.Paragraph(
        text: recipe.notes.trim().isEmpty ? 'None' : recipe.notes.trim(),
        style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
      ),
      pw.SizedBox(height: 14),
      pw.Text(
        'PDF printout for reference. Use the app’s JSON backup for an editable recipe.',
        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
      ),
    ];
  }

  static pw.Widget _section(String title) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 7),
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 7),
    color: PdfColors.grey200,
    child: pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        color: PdfColors.brown800,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.6,
      ),
    ),
  );

  static pw.Widget _field(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value),
        ],
        style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
      ),
    ),
  );

  static pw.Widget _fragranceHeader() => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      children: [
        pw.Expanded(flex: 6, child: _tableHeading('Fragrance')),
        pw.Expanded(flex: 2, child: _tableHeading('Blend')),
        pw.Expanded(flex: 3, child: _tableHeading('Each (g)')),
        pw.Expanded(flex: 3, child: _tableHeading('Batch (g)')),
      ],
    ),
  );

  static pw.Widget _tableHeading(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      color: PdfColors.grey700,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
    ),
  );

  static pw.Widget _fragranceRow(RecipeFragrancePrintData fragrance) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Text(
                fragrance.name,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                fragrance.sharePercent == null
                    ? 'N/A'
                    : '${_grams(fragrance.sharePercent)}%',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                _grams(fragrance.perContainerGrams),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                _grams(fragrance.batchGrams),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );

  static String _value(String value) =>
      value.trim().isEmpty ? 'Not specified' : value.trim();

  static String _grams(double? value) =>
      value == null ? 'N/A' : value.toStringAsFixed(2);
}
