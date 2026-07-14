enum ExtractionTier { ruleBased, onDeviceLlm, cloudLlm, manual }

class ExtractedTransaction {
  final String? title;
  final double? amount;
  final String? categoryTitle;
  final bool? isIncome;
  final double confidence;
  final ExtractionTier source;

  const ExtractedTransaction({
    this.title,
    this.amount,
    this.categoryTitle,
    this.isIncome,
    required this.confidence,
    required this.source,
  });

  @override
  String toString() {
    return '$title, $isIncome, $amount, $categoryTitle, $confidence, ${source.name}';
  }

  bool get isComplete =>
      title != null &&
      amount != null &&
      categoryTitle != null &&
      isIncome != null;

  ExtractedTransaction copyWith({
    String? title,
    double? amount,
    String? categoryTitle,
    bool? isIncome,
    double? confidence,
    ExtractionTier? source,
  }) {
    return ExtractedTransaction(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      isIncome: isIncome ?? this.isIncome,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
    );
  }
}
