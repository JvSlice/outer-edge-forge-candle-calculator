import 'dart:typed_data';
import 'dart:js_interop';

import 'package:file_selector/file_selector.dart';
import 'package:web/web.dart' as web;

/// Web backup transfer. The JSON itself is validated by RecipeRepository.
class RecipeFileIo {
  const RecipeFileIo._();

  static Future<String?> pickJson() async {
    const type = XTypeGroup(
      label: 'JSON backup',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final file = await openFile(acceptedTypeGroups: [type]);
    if (file == null) return null;
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Backup is too large (5 MB maximum).');
    }
    return file.readAsString();
  }

  static void downloadJson(
    String contents, {
    String fileName = 'oef-candle-recipes.json',
  }) {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(
      const Duration(seconds: 1),
      () => web.URL.revokeObjectURL(url),
    );
  }

  static void downloadText(String contents, String fileName, String mimeType) {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(
      const Duration(seconds: 10),
      () => web.URL.revokeObjectURL(url),
    );
  }

  static Future<bool> sharePdf(Uint8List contents, String fileName) async {
    final file = web.File(
      [contents.toJS].toJS,
      fileName,
      web.FilePropertyBag(type: 'application/pdf'),
    );
    final shareData = web.ShareData(
      files: [file].toJS,
      title: 'OEF candle recipe printout',
      text: 'PDF printout. Use Export JSON for an editable recipe backup.',
    );
    final navigator = web.window.navigator;
    // Touch devices can share the PDF; desktop browsers always get a download.
    if (!web.window.matchMedia('(pointer: coarse)').matches) return false;
    try {
      if (!navigator.canShare(shareData)) return false;
    } catch (_) {
      return false;
    }
    await navigator.share(shareData).toDart;
    return true;
  }

  static void downloadPdf(Uint8List contents, String fileName) {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(
      const Duration(seconds: 30),
      () => web.URL.revokeObjectURL(url),
    );
  }

  static bool openPdfForPrinting(Uint8List contents) {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final opened = web.window.open(url, '_blank');
    if (opened == null) {
      web.URL.revokeObjectURL(url);
      return false;
    }
    Future.delayed(
      const Duration(minutes: 2),
      () => web.URL.revokeObjectURL(url),
    );
    return true;
  }
}
