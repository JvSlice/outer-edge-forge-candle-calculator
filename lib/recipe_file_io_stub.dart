/// Native test fallback. The shipped app uses the web implementation.
class RecipeFileIo {
  const RecipeFileIo._();

  static Future<String?> pickJson() async => null;

  static void downloadJson(String contents) =>
      throw UnsupportedError('JSON download is available in the web app.');
}
