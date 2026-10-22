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

  static void downloadJson(String contents) {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = 'oef-candle-recipes.json';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(
      const Duration(seconds: 1),
      () => web.URL.revokeObjectURL(url),
    );
  }
}
