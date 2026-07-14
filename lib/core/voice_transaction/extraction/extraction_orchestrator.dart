import 'package:stacked/stacked_annotations.dart';
import 'package:walleta/core/logger/logger_service.dart';
import 'package:walleta/core/voice_transaction/extraction/on_device_llm_extraction_service.dart';
import 'package:walleta/core/voice_transaction/extraction/rule_based_extraction_service.dart';
import 'package:walleta/core/voice_transaction/model/extracted_transaction.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';

@LazySingleton()
class ExtractionOrchestrator {
  final RuleBasedExtractionService _ruleBased;
  final OnDeviceLlmExtractionService _onDeviceLlm;
  final Log _log = Log(ExtractionOrchestrator);

  ExtractionOrchestrator(this._ruleBased, this._onDeviceLlm);

  static const _confidenceThreshold = 0.7;

  // Expose model state for UI
  bool get isModelLoaded => _onDeviceLlm.isModelLoaded;
  bool get isDownloading => _onDeviceLlm.isDownloading;
  double get downloadProgress => _onDeviceLlm.downloadProgress;

  Future<bool> checkModelInstalled() => _onDeviceLlm.checkModelInstalled();

  Future<bool> hasPartialDownload() => _onDeviceLlm.hasPartialDownload();

  void cancelDownload() => _onDeviceLlm.cancelDownload();

  Future<void> downloadModel({void Function(double)? onProgress}) =>
      _onDeviceLlm.downloadModel(onProgress: onProgress);

  Future<ExtractedTransaction> extract(
    String text,
    List<Category> categories, {
    String language = 'en-US',
  }) async {
    final ruleResult = await _ruleBased.extract(
      text,
      categories,
      language: language,
    );
    if (ruleResult.confidence >= _confidenceThreshold &&
        ruleResult.isComplete) {
      return ruleResult;
    }

    // Tier 2: On-device LLM (if model loaded)
    if (_onDeviceLlm.isModelLoaded) {
      try {
        _log.d('llm-start');
        final llmResult = await _onDeviceLlm.extract(
          text,
          categories,
          language: language,
        );
        _log.d('llm-result $llmResult');
        if (llmResult.isComplete) return llmResult;
      } catch (_) {
        // Fall through to return rule-based result
      }
    }

    // Future: Tier 3 (cloud LLM) would go here

    return ruleResult;
  }
}
