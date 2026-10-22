import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'app_colors.dart';
import 'recipe_file_io.dart';

class RecipePdfActionsPage extends StatefulWidget {
  const RecipePdfActionsPage({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.recipeCount,
    required this.batchCount,
  });

  final Uint8List bytes;
  final String fileName;
  final int recipeCount;
  final int batchCount;

  @override
  State<RecipePdfActionsPage> createState() => _RecipePdfActionsPageState();
}

class _RecipePdfActionsPageState extends State<RecipePdfActionsPage> {
  bool _working = false;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _print() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (kIsWeb) {
        if (!RecipeFileIo.openPdfForPrinting(widget.bytes)) {
          _message(
            'Your browser blocked the PDF tab. Use Save / Share PDF instead.',
          );
        }
      } else {
        await Printing.layoutPdf(
          name: widget.fileName,
          onLayout: (_) async => widget.bytes,
        );
      }
    } catch (error) {
      _message('Could not open the printout: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _saveOrShare() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (kIsWeb) {
        final shared = await RecipeFileIo.sharePdf(
          widget.bytes,
          widget.fileName,
        );
        if (!shared) RecipeFileIo.downloadPdf(widget.bytes, widget.fileName);
      } else {
        await Printing.sharePdf(
          bytes: widget.bytes,
          filename: widget.fileName,
          subject: 'OEF candle recipe printout',
        );
      }
    } catch (error) {
      _message('Could not share the PDF: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recipe PDF printout')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.copper,
                      size: 38,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your PDF is ready',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.recipeCount} recipe${widget.recipeCount == 1 ? '' : 's'} · ${widget.batchCount} containers per recipe',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'This white-background printout includes both per-container and batch amounts. It is for printing and reference; use Export JSON for an editable backup.',
                      style: TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        key: const Key('print-recipe-pdf'),
                        onPressed: _working ? null : _print,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Open PDF to print'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        key: const Key('save-share-recipe-pdf'),
                        onPressed: _working ? null : _saveOrShare,
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Save / Share PDF'),
                      ),
                    ),
                    if (_working) ...[
                      const SizedBox(height: 18),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
