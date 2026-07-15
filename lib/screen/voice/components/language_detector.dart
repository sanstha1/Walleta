class LanguageDetector {
  static const _nepaliPattern = r'[\u0900-\u097F]';

  static String detectLocale(String text) {
    final hasNepali = RegExp(_nepaliPattern).hasMatch(text);
    return hasNepali ? 'ne-NP' : 'en-US';
  }

  static bool isNepali(String text) => RegExp(_nepaliPattern).hasMatch(text);
}
