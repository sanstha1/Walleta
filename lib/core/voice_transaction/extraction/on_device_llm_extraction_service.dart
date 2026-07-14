import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:walleta/core/logger/logger_service.dart';
import 'package:walleta/core/voice_transaction/extraction/transaction_extraction_service.dart';
import 'package:walleta/core/voice_transaction/model/extracted_transaction.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';

@LazySingleton()
class OnDeviceLlmExtractionService implements TransactionExtractionService {
  final Log _log = Log(OnDeviceLlmExtractionService);

  @override
  ExtractionTier get tier => ExtractionTier.onDeviceLlm;

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  dio.CancelToken? _cancelToken;

  // TODO: Replace with your CDN URL once self-hosted
  static const _modelFileName = 'gemma3-1b-it-int4.task';
  static const _tmpModelFileName = 'gemma3-1b-it-int4.task.tmp';
  static const _driveFileId = '1fK9K5ftGx4jN3y0OT0igHYUka6ed_HKB';
  static const _minModelSizeBytes = 1048576; // 1 MB

  // Keyword hints to map common words to categories.
  static const _categoryKeywords = <String, List<String>>{
    'Food': [
      'restaurant',
      'meal',
      'lunch',
      'dinner',
      'breakfast',
      'snack',
      'coffee',
      'drink',
      'food',
      'eat',
      'pizza',
      'burger',
      'hotdog',
    ],
    'Transport': [
      'car',
      'taxi',
      'uber',
      'bus',
      'train',
      'fuel',
      'gas',
      'ride',
      'flight',
      'parking',
    ],
    'Shopping': [
      'clothes',
      'shoes',
      'store',
      'amazon',
      'online',
      'electronics',
    ],
    'Groceries': [
      'grocery',
      'supermarket',
      'vegetables',
      'fruits',
      'milk',
      'bread',
    ],
    'Education': [
      'school',
      'college',
      'course',
      'book',
      'tuition',
      'class',
      'study',
    ],
  };

  Future<String> _getModelFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_modelFileName';
  }

  Future<String> _getTmpFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_tmpModelFileName';
  }

  Future<bool> checkModelInstalled() async {
    final filePath = await _getModelFilePath();
    final file = File(filePath);
    _isModelLoaded =
        file.existsSync() && file.lengthSync() > _minModelSizeBytes;
    if (_isModelLoaded) {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(filePath).install();
    }
    return _isModelLoaded;
  }

  /// Whether a partial download exists that can be resumed.
  Future<bool> hasPartialDownload() async {
    final tmpPath = await _getTmpFilePath();
    final tmpFile = File(tmpPath);
    return tmpFile.existsSync() && tmpFile.lengthSync() > 0;
  }

  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled');
    _cancelToken = null;
  }

  Future<void> downloadModel({void Function(double)? onProgress}) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0.0;
    _cancelToken = dio.CancelToken();

    try {
      final filePath = await _getModelFilePath();
      final tmpPath = await _getTmpFilePath();
      final tmpFile = File(tmpPath);

      final dio = dio.Dio(
        dio.BaseOptions(followRedirects: true, maxRedirects: 10),
      );
      final downloadUrl =
          'https://drive.usercontent.google.com/download?id=$_driveFileId&export=download&confirm=t';

      // Check for existing partial download to resume
      int existingBytes = 0;
      if (tmpFile.existsSync()) {
        existingBytes = tmpFile.lengthSync();
        // Only resume if partial file is large enough to be actual data
        if (existingBytes < _minModelSizeBytes) {
          tmpFile.deleteSync();
          existingBytes = 0;
        }
      }

      final Options options = Options(
        headers: existingBytes > 0
            ? {HttpHeaders.rangeHeader: 'bytes=$existingBytes-'}
            : null,
      );

      await dio.download(
        downloadUrl,
        tmpPath,
        options: options,
        cancelToken: _cancelToken,
        deleteOnError: false,
        fileAccessMode: existingBytes > 0
            ? FileAccessMode.append
            : FileAccessMode.write,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final totalWithExisting = total + existingBytes;
            final receivedWithExisting = received + existingBytes;
            _downloadProgress = receivedWithExisting / totalWithExisting;
            onProgress?.call(_downloadProgress);
          }
        },
      );

      // Verify we got the actual model, not an HTML page
      if (!tmpFile.existsSync() || tmpFile.lengthSync() < _minModelSizeBytes) {
        if (tmpFile.existsSync()) tmpFile.deleteSync();
        throw Exception(
          'Download failed: received HTML page instead of model file. '
          'The Google Drive link may have expired or hit a quota limit.',
        );
      }

      // Move completed download to final path
      tmpFile.renameSync(filePath);

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(filePath).install();

      _isModelLoaded = true;
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        _log.d('Model download cancelled, partial file kept for resume');
        return;
      }
      rethrow;
    } finally {
      _isDownloading = false;
      _cancelToken = null;
    }
  }

  @override
  Future<ExtractedTransaction> extract(
    String text,
    List<Category> categories, {
    String language = 'en-US',
  }) async {
    if (!_isModelLoaded) throw StateError('On-device model not loaded');

    final categoryNames = categories
        // ignore: unnecessary_null_comparison
        .where((c) => c.title != null)
        .map((c) => c.title)
        .toList();

    final categoryHints = _buildCategoryHints(categoryNames);
    final categoriesStr = categoryNames.join(', ');

    // ── Language-aware prompt ──────────────────────────────────────────────
    final langInstruction = language == 'ne-NP'
        ? 'The text is in Nepali. Extract the transaction. '
              'Common Nepali words: खर्च=expense, तिरें/गरें=paid/spent, '
              'रुपैयाँ/रु=rupees, खाना=food, यातायात=transport, किनमेल=shopping. '
              'isIncome true for: पाएँ/कमाएँ/तलब/आम्दानी.'
        : 'The text is in English. Extract the financial transaction. ';

    final prompt =
        '$langInstruction'
        'Reply with ONLY a JSON object, no other text.\n'
        'If the text contains NO numeric amount, set "amount" to 0.\n'
        'Categories: $categoriesStr. $categoryHints\n'
        'Format: {"title":"...","amount":NUMBER,"category":"...","isIncome":BOOL}\n'
        'isIncome is true ONLY for salary/earned/received/refund.\n'
        'Text: "$text"';

    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
    final chat = await model.createChat(
      modelType: ModelType.gemmaIt,
      temperature: 0.1,
    );

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

    final textBuffer = StringBuffer();

    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        textBuffer.write(response.token);
      }
    }

    ExtractedTransaction? result;
    if (textBuffer.isNotEmpty) {
      final rawText = textBuffer.toString();
      _log.d('model response: $rawText');
      result = _tryParseJsonResponse(rawText, categoryNames, text);
    }

    await model.close();

    return result ??
        const ExtractedTransaction(
          amount: 0.0,
          confidence: 0.0,
          source: ExtractionTier.onDeviceLlm,
        );
  }

  // Build compact category hints for the prompt.
  static String _buildCategoryHints(List<String> categoryNames) {
    final hints = <String>[];
    for (final name in categoryNames) {
      final keywords = _categoryKeywords[name];
      if (keywords != null) {
        hints.add('$name=${keywords.take(4).join("/")}');
      }
    }
    return hints.isEmpty ? '' : 'Hints: ${hints.join(", ")}';
  }

  /// Build [ExtractedTransaction] from args map.
  ExtractedTransaction _extractionFromArgs(
    Map<String, dynamic> args,
    List<String> categoryNames,
    String originalText,
  ) {
    final rawCategory = args['category']?.toString();
    final matchedCategory = _matchToValidCategory(rawCategory, categoryNames);

    var amount = _toDouble(args['amount']);
    var isIncome = _toBool(args['isIncome']);

    // Only fall back to text scan if model gave null (not 0)
    amount ??= _extractAmountFromText(originalText);

    // Treat 0 or negative as "not provided" → display as 0.0
    if (amount != null && amount <= 0) amount = 0.0;

    isIncome ??= _inferIsIncomeFromText(originalText);

    return ExtractedTransaction(
      title: args['title']?.toString(),
      // Always 0.0 when nothing valid was found — never null
      amount: amount ?? 0.0,
      categoryTitle: matchedCategory,
      isIncome: isIncome,
      confidence: matchedCategory != null ? 0.9 : 0.7,
      source: ExtractionTier.onDeviceLlm,
    );
  }

  /// Parse JSON from model text response.
  /// Extracts the first JSON object found in the text.
  ExtractedTransaction? _tryParseJsonResponse(
    String text,
    List<String> categoryNames,
    String originalText,
  ) {
    // Find first { ... } block in the response
    final regex = RegExp(r'\{[^{}]*\}', dotAll: true);
    final match = regex.firstMatch(text);
    if (match == null) {
      _log.w('no JSON object found in model response');
      return null;
    }

    try {
      final args = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return _extractionFromArgs(args, categoryNames, originalText);
    } catch (e) {
      _log.w('JSON parse failed: $e');
      return null;
    }
  }

  /// Map the model's category output to a valid category name.
  /// Tries: exact -> case-insensitive -> keyword lookup -> fuzzy similarity.
  String? _matchToValidCategory(
    String? modelCategory,
    List<String> validCategories,
  ) {
    if (modelCategory == null || validCategories.isEmpty) return null;

    // Exact match
    if (validCategories.contains(modelCategory)) return modelCategory;

    final lower = modelCategory.toLowerCase();

    // Case-insensitive match
    for (final valid in validCategories) {
      if (valid.toLowerCase() == lower) return valid;
    }

    // Keyword-based semantic match (car -> Transport, restaurant -> Food)
    for (final valid in validCategories) {
      final keywords = _categoryKeywords[valid];
      if (keywords == null) continue;
      for (final kw in keywords) {
        if (lower.contains(kw) || kw.contains(lower)) return valid;
      }
    }

    // Fuzzy string similarity
    String? bestMatch;
    double bestScore = 0.0;
    for (final valid in validCategories) {
      final score = StringSimilarity.compareTwoStrings(
        lower,
        valid.toLowerCase(),
      );
      if (score > bestScore) {
        bestScore = score;
        bestMatch = valid;
      }
    }
    if (bestScore >= 0.4 && bestMatch != null) return bestMatch;

    return null;
  }

  // --- Helpers to recover missing values from original text ---

  // FIX: digits are REQUIRED — currency words alone never match.
  static final _numericRegex = RegExp(
    r'(?:[\$₹£€¥])\s*(\d+[\.,]?\d*)'
    r'|(\d+[\.,]?\d+|\d+)\s*(?:dollars?|rupees?|rs\.?|npr|usd|bucks?)\b',
    caseSensitive: false,
  );

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
  ];

  static double? _extractAmountFromText(String text) {
    final lower = text.toLowerCase();
    final match = _numericRegex.firstMatch(lower);
    if (match != null) {
      final numStr = (match.group(1) ?? match.group(2) ?? '').replaceAll(
        ',',
        '',
      );
      if (numStr.isEmpty) return null;
      final amount = double.tryParse(numStr);
      if (amount != null && amount > 0) return amount;
    }
    return null;
  }

  static bool _inferIsIncomeFromText(String text) {
    final lower = text.toLowerCase();
    return _incomeKeywords.any((kw) => lower.contains(kw));
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final str = v.toString().trim();
    return double.tryParse(str);
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }
}
