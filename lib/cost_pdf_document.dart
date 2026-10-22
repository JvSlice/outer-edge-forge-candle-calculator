import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cost_calculator.dart';
import 'saved_costs.dart';

class CostPdfDocument {
  const CostPdfDocument._();

  static Future<Uint8List> build(SavedCostCalculation record) async {
    final recipe = record.recipeSnapshot;
    final result = CostCalculator.calculate(
      waxGrams: double.parse(recipe.waxGrams),
      loadPercent: recipe.loadPercent,
      shares: recipe.fragrances.map((f) => double.parse(f.percent)).toList(),
      wickQuantity: int.parse(recipe.wickQuantity),
      containerCount: record.containerCount,
      costs: recipe.costs!,
    );
    final logo = pw.MemoryImage(
      (await rootBundle.load(
        'assets/branding/oef-icon-original.png',
      )).buffer.asUint8List(),
    );
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
    final doc = pw.Document(title: record.name, author: 'Outer Edge Forge');
    String money(double? value) =>
        value == null ? 'Missing' : '\$${CostCalculator.currencyUp(value)}';
    final tableRows = <List<String>>[
      [
        'Material',
        'Quantity / container',
        'Batch quantity',
        'Purchase assumption',
        'Cost / container',
        'Batch cost',
      ],
      [
        recipe.waxType.isEmpty ? 'Wax' : recipe.waxType,
        '${recipe.waxGrams} g',
        '${result.waxGramsBatch.toStringAsFixed(2)} g',
        '\$${recipe.costs!.waxPrice} / ${recipe.costs!.waxPounds} lb',
        money(result.waxCost),
        money(
          result.waxCost == null
              ? null
              : result.waxCost! * record.containerCount,
        ),
      ],
      for (var i = 0; i < recipe.fragrances.length; i++)
        [
          '${recipe.fragrances[i].name.isEmpty ? 'Fragrance ${i + 1}' : recipe.fragrances[i].name} (${recipe.fragrances[i].percent}%)',
          '${result.fragranceGramsEach[i].toStringAsFixed(2)} g',
          '${(result.fragranceGramsEach[i] * record.containerCount).toStringAsFixed(2)} g',
          '${recipe.costs!.fragrances[i].price} / ${recipe.costs!.fragrances[i].size} ${recipe.costs!.fragrances[i].unit.name}${recipe.costs!.fragrances[i].density.isEmpty ? '' : ', ${recipe.costs!.fragrances[i].density} g/mL'}${recipe.costs!.fragrances[i].netGrams.isEmpty ? '' : ', ${recipe.costs!.fragrances[i].netGrams} g net'}',
          money(result.fragranceCosts[i]),
          money(
            result.fragranceCosts[i] == null
                ? null
                : result.fragranceCosts[i]! * record.containerCount,
          ),
        ],
      [
        'Wicks',
        '${recipe.wickQuantity} each',
        '${int.parse(recipe.wickQuantity) * record.containerCount} each',
        '\$${recipe.costs!.wickUnitCost} each',
        money(result.wickCost),
        money(
          result.wickCost == null
              ? null
              : result.wickCost! * record.containerCount,
        ),
      ],
      [
        'Vessel',
        '1 each',
        '${record.containerCount} each',
        '\$${recipe.costs!.vesselCost} each',
        money(result.vesselCost),
        money(
          result.vesselCost == null
              ? null
              : result.vesselCost! * record.containerCount,
        ),
      ],
      [
        'Additional',
        '1 each',
        '${record.containerCount} each',
        '\$${recipe.costs!.additionalCost} each',
        money(result.additionalCost),
        money(
          result.additionalCost == null
              ? null
              : result.additionalCost! * record.containerCount,
        ),
      ],
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (_) => [
          pw.Row(
            children: [
              pw.SizedBox(width: 42, height: 42, child: pw.Image(logo)),
              pw.SizedBox(width: 12),
              pw.Text(
                'OUTER EDGE FORGE · MATERIAL COST',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            record.name,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Linked recipe: ${record.linkedRecipeName ?? 'Standalone snapshot'}',
          ),
          pw.Text(
            'Saved: ${record.createdAt.toLocal()}    Updated: ${record.updatedAt.toLocal()}    Batch: ${record.containerCount} containers',
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Material costs only. Totals exclude labor, taxes, selling fees, and profit.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          if (result.missing.isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.orange100,
              child: pw.Text(
                'INCOMPLETE TOTAL — missing or invalid: ${result.missing.join(', ')}',
              ),
            ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            data: tableRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: .4),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total material cost per container: ${money(result.materialCostPerContainer)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Total material cost for batch: ${money(result.materialCostBatch)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Snapshot inputs: ${recipe.waxGrams} g wax, ${recipe.loadPercent}% fragrance load, ${recipe.wickQuantity} wicks per container. Purchase prices and quantities above are saved assumptions and are not updated from later recipe edits.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return Uint8List.fromList(await doc.save());
  }
}
