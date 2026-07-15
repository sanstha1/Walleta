import 'package:stacked/stacked_annotations.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:walleta/core/voice_transaction/extraction/transaction_extraction_service.dart';
import 'package:walleta/core/voice_transaction/model/extracted_transaction.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';

@LazySingleton()
class RuleBasedExtractionService implements TransactionExtractionService {
  static const _expenseKeywords = [
    'spent',
    'paid',
    'bought',
    'cost',
    'charged',
    'expense',
    'bill',
    'payment',
    'pay',
    'purchase',
    'shopping',
  ];

  static const _incomeKeywords = [
    'received',
    'earned',
    'salary',
    'income',
    'got paid',
    'refund',
    'credited',
    'bonus',
    'deposit',
    'wage',
    'freelance',
  ];

  // ── Nepali keyword lists (Devanagari) ─────────────────────────────────────
  static const _nepaliExpenseKeywords = [
    'खर्च',
    'तिरें',
    'किनें',
    'लिएँ',
    'गरें',
    'खाएँ',
    'किनमेल',
  ];

  static const _nepaliIncomeKeywords = [
    'पाएँ',
    'कमाएँ',
    'तलब',
    'आम्दानी',
    'बोनस',
    'जम्मा',
    'फिर्ता',
  ];

  static const _noiseWords = [
    'on',
    'for',
    'the',
    'a',
    'an',
    'of',
    'in',
    'to',
    'from',
    'my',
    'i',
    'and',
    'with',
    'at',
    'just',
    'about',
    'around',
    'some',
    'today',
    'yesterday',
  ];

  // FIX: digits are REQUIRED before the optional currency suffix.
  // The second alternative uses \b so bare currency words (e.g. "dollar")
  // never match on their own.
  static final _amountRegex = RegExp(
    r'(?:[\$₹£€¥रु])\s*(\d+[\.,]?\d*)'
    r'|(\d+[\.,]?\d+|\d+)\s*(?:dollars?|rupees?|rs\.?|npr|usd|gbp|eur|bucks?|रुपैयाँ|रु\.?)\b',
    caseSensitive: false,
  );

  @override
  ExtractionTier get tier => ExtractionTier.ruleBased;

  @override
  Future<ExtractedTransaction> extract(
    String text,
    List<Category> categories, {
    String language = 'en-US',
  }) async {
    final lowerText = text.toLowerCase().trim();
    double confidence = 0.0;

    // ── Pick keyword lists based on detected language ──────────────────────
    final expenseKw = language == 'ne-NP'
        ? [..._expenseKeywords, ..._nepaliExpenseKeywords]
        : _expenseKeywords;

    final incomeKw = language == 'ne-NP'
        ? [..._incomeKeywords, ..._nepaliIncomeKeywords]
        : _incomeKeywords;

    // 1. Extract amount (nullable — null means nothing found)
    final amountResult = _extractAmount(lowerText);
    final amount = amountResult.amount;
    if (amount != null) confidence += 0.35;

    // 2. Detect income/expense
    final typeResult = _detectTransactionType(lowerText, incomeKw, expenseKw);
    final isIncome = typeResult.isIncome;
    if (typeResult.hasKeyword) confidence += 0.2;

    // 3. Match category
    final remainingText = _removeMatched(
      lowerText,
      amountResult.matchedString,
      typeResult.matchedKeywords,
    );
    final categoryResult = _matchCategory(remainingText, categories);
    if (categoryResult.categoryTitle != null && categoryResult.score >= 0.5) {
      confidence += 0.25;
    }

    // 4. Extract title
    final title = _extractTitle(remainingText, categoryResult.matchedToken);
    if (title != null && title.isNotEmpty) confidence += 0.2;

    return ExtractedTransaction(
      title: title,
      // Default to 0.0 when no numeric amount was found in the text
      amount: amount ?? 0.0,
      categoryTitle: categoryResult.categoryTitle,
      isIncome: isIncome,
      confidence: confidence,
      source: ExtractionTier.ruleBased,
    );
  }

  _AmountResult _extractAmount(String text) {
    final match = _amountRegex.firstMatch(text);
    if (match == null) return const _AmountResult(null, '');

    final numStr = (match.group(1) ?? match.group(2) ?? '').replaceAll(',', '');
    if (numStr.isEmpty) return const _AmountResult(null, '');
    final amount = double.tryParse(numStr);
    // Reject zero or negative — treat as "not found"
    if (amount == null || amount <= 0) return const _AmountResult(null, '');
    return _AmountResult(amount, match.group(0) ?? '');
  }

  // ── Now accepts dynamic keyword lists ─────────────────────────────────────
  _TypeResult _detectTransactionType(
    String text,
    List<String> incomeKeywords,
    List<String> expenseKeywords,
  ) {
    final matchedKeywords = <String>[];

    // Check income keywords first (multi-word phrases included)
    for (final keyword in incomeKeywords) {
      if (text.contains(keyword)) {
        return _TypeResult(true, true, [keyword]);
      }
    }

    // Check expense keywords
    for (final keyword in expenseKeywords) {
      if (text.contains(keyword)) {
        matchedKeywords.add(keyword);
      }
    }

    if (matchedKeywords.isNotEmpty) {
      return _TypeResult(false, true, matchedKeywords);
    }

    // Default to expense
    return const _TypeResult(false, false, []);
  }

  String _removeMatched(
    String text,
    String amountMatch,
    List<String> keywords,
  ) {
    var result = text;
    if (amountMatch.isNotEmpty) {
      result = result.replaceFirst(amountMatch, ' ');
    }
    for (final keyword in keywords) {
      result = result.replaceFirst(keyword, ' ');
    }
    return result.trim();
  }

  _CategoryResult _matchCategory(String text, List<Category> categories) {
    if (categories.isEmpty || text.isEmpty) {
      return const _CategoryResult(null, 0.0, null);
    }

    final tokens = text
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_noiseWords.contains(t))
        .toList();

    if (tokens.isEmpty) return const _CategoryResult(null, 0.0, null);

    String? bestCategory;
    double bestScore = 0.0;
    String? bestToken;

    for (final category in categories) {
      final catTitle = category.title.toLowerCase();
      // Exact substring match first
      if (text.contains(catTitle)) {
        return _CategoryResult(category.title, 1.0, catTitle);
      }

      // Fuzzy match individual tokens
      for (final token in tokens) {
        final score = StringSimilarity.compareTwoStrings(token, catTitle);
        if (score > bestScore && score >= 0.4) {
          bestScore = score;
          bestCategory = category.title;
          bestToken = token;
        }
      }
    }

    return _CategoryResult(bestCategory, bestScore, bestToken);
  }

  String? _extractTitle(String remainingText, String? categoryToken) {
    var text = remainingText;
    if (categoryToken != null && categoryToken.isNotEmpty) {
      text = text.replaceFirst(categoryToken, ' ');
    }

    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_noiseWords.contains(w))
        .toList();

    if (words.isEmpty) return categoryToken;

    return words.join(' ').trim();
  }
}

class _AmountResult {
  final double? amount;
  final String matchedString;
  const _AmountResult(this.amount, this.matchedString);
}

class _TypeResult {
  final bool isIncome;
  final bool hasKeyword;
  final List<String> matchedKeywords;
  const _TypeResult(this.isIncome, this.hasKeyword, this.matchedKeywords);
}

class _CategoryResult {
  final String? categoryTitle;
  final double score;
  final String? matchedToken;
  const _CategoryResult(this.categoryTitle, this.score, this.matchedToken);
}
