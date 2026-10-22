import 'dart:typed_data';

/// Native test fallback. The shipped app uses the web implementation.
class RecipeFileIo {
  const RecipeFileIo._();

  static Future<String?> pickJson() async => null;

  static void downloadJson(
    String contents, {
    String fileName = 'oef-candle-recipes.json',
  }) => throw UnsupportedError('JSON download is available in the web app.');

  static void downloadText(String contents, String fileName, String mimeType) =>
      throw UnsupportedError('File download is available in the web app.');

  static Future<bool> sharePdf(Uint8List contents, String fileName) async =>
      false;

  static void downloadPdf(Uint8List contents, String fileName) =>
      throw UnsupportedError('PDF download is available in the web app.');

  static bool openPdfForPrinting(Uint8List contents) => false;
}
