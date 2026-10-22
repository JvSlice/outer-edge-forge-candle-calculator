import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'app_colors.dart';
import 'recipe_file_io.dart';

class CostPdfActionsPage extends StatefulWidget {
  const CostPdfActionsPage({
    super.key,
    required this.bytes,
    required this.fileName,
  });
  final Uint8List bytes;
  final String fileName;
  @override
  State<CostPdfActionsPage> createState() => _CostPdfActionsPageState();
}

class _CostPdfActionsPageState extends State<CostPdfActionsPage> {
  bool _working = false;
  Future<void> _act({required bool share}) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (kIsWeb) {
        if (share) {
          final didShare = await RecipeFileIo.sharePdf(
            widget.bytes,
            widget.fileName,
          );
          if (!didShare) {
            RecipeFileIo.downloadPdf(widget.bytes, widget.fileName);
          }
        } else if (!RecipeFileIo.openPdfForPrinting(widget.bytes)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Browser blocked the PDF tab. Use Save / Share PDF instead.',
              ),
            ),
          );
        }
      } else if (share) {
        await Printing.sharePdf(
          bytes: widget.bytes,
          filename: widget.fileName,
          subject: 'OEF material cost calculation',
        );
      } else {
        await Printing.layoutPdf(
          name: widget.fileName,
          onLayout: (_) async => widget.bytes,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not handle PDF: $error')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cost PDF')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.copper,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your cost report is ready',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Includes saved purchase assumptions, material quantities, per-container and batch costs, and any incomplete cost inputs. Material totals exclude labor, taxes, selling fees, and profit.',
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _working ? null : () => _act(share: false),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Open PDF to print'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _working ? null : () => _act(share: true),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Save / Share PDF'),
                    ),
                  ),
                  if (_working)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
