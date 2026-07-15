import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:stacked/stacked.dart';
import 'package:walleta/config/api_config.dart';
import 'package:walleta/core/logger/logger_service.dart';
import 'package:walleta/core/voice_transaction/extraction/extraction_orchestrator.dart';
import 'package:walleta/core/voice_transaction/extraction/on_device_llm_extraction_service.dart';
import 'package:walleta/core/voice_transaction/extraction/rule_based_extraction_service.dart';
import 'package:walleta/core/voice_transaction/model/extracted_transaction.dart';
import 'package:walleta/screen/category/view/add_new_categories.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';
import 'package:walleta/services/token_service.dart';

enum VoiceState { idle, listening, processing, error, complete }

class RecordVoiceViewModel extends BaseViewModel {
  final Log _log = Log(RecordVoiceViewModel);
  final SpeechService _speechService = SpeechService();

  final ExtractionOrchestrator _orchestrator = ExtractionOrchestrator(
    RuleBasedExtractionService(),
    OnDeviceLlmExtractionService(),
  );

  bool _isDisposed = false;

  bool _isNepali = false;
  bool get isNepali => _isNepali;

  String _activeLocale = 'en-US';
  String get activeLocale => _activeLocale;

  void toggleLanguage() {
    _isNepali = !_isNepali;
    _activeLocale = _isNepali ? 'ne-NP' : 'en-US';
    notifyListeners();
  }

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  void changeState(VoiceState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  String _partialText = '';
  String get partialText => _partialText;

  String _finalText = '';
  String get finalText => _finalText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ExtractedTransaction? _extraction;
  ExtractedTransaction? get extraction => _extraction;

  bool get isModelLoaded => _orchestrator.isModelLoaded;
  bool get isDownloading => _orchestrator.isDownloading;
  double get downloadProgress => _orchestrator.downloadProgress;

  Future<void> initialize() async {
    await fetchCategories();
    await _speechService.initialize();
    final installed = await _orchestrator.checkModelInstalled();
    if (!installed && await _orchestrator.hasPartialDownload()) {
      downloadAiModel();
    }
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> downloadAiModel() async {
    if (_isDisposed) return;
    notifyListeners();
    try {
      await _orchestrator.downloadModel(
        onProgress: (_) {
          if (!_isDisposed) notifyListeners();
        },
      );
      // ignore: empty_catches
    } catch (e) {}
    if (!_isDisposed) notifyListeners();
  }

  List<Category> _categories = [];

  static final String _baseUrl = '${ApiConfig.baseUrl}/api';

  Future<void> fetchCategories() async {
    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();
      final cleanEmail = userEmail?.trim() ?? "";

      final response = await http.get(
        Uri.parse('$_baseUrl/categories?email=$cleanEmail'),
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((item) => Category.fromJson(item)).toList();
        debugPrint(
          'DEBUG: Found ${_categories.length} categories for $cleanEmail',
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (!_isDisposed) {
        setBusy(false);
        notifyListeners();
      }
    }
  }

  Future<void> onMicPressed() async {
    if (_isDisposed) return;

    if (_state == VoiceState.listening) {
      await _stopAndProcess();
      return;
    }

    _log.d(_speechService.isAvailable, tag: 'speech-service-available');

    if (!_speechService.isAvailable) {
      final available = await _speechService.initialize();
      if (_isDisposed) return;
      if (!available) {
        _state = VoiceState.error;
        _errorMessage = "Speech recognition not available";
        notifyListeners();
        return;
      }
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    if (_isDisposed) return;

    final localeId = _isNepali ? 'ne-NP' : 'en-US';
    _activeLocale = localeId;

    _state = VoiceState.listening;
    _partialText = '';
    _finalText = '';
    notifyListeners();

    await _speechService.startListening(
      localeId: localeId,
      onResult: (text) {
        if (_isDisposed) return;
        _finalText = text;
        _stopAndProcess();
      },
      onPartial: (text) {
        if (_isDisposed) return;
        _partialText = text;
        notifyListeners();
      },
    );
  }

  Future<ExtractedTransaction?> _stopAndProcess() async {
    if (_isDisposed) return null;

    await _speechService.stopListening();

    if (_finalText.isEmpty) _finalText = _partialText;
    if (_finalText.isEmpty) {
      if (_isDisposed) return null;
      _state = VoiceState.error;
      _errorMessage = "Didn't catch that. Please try again.";
      notifyListeners();
      return null;
    }

    if (_isDisposed) return null;
    _state = VoiceState.processing;
    notifyListeners();

    try {
      final language = _isNepali ? 'ne-NP' : 'en-US';
      _extraction = await _orchestrator.extract(
        _finalText,
        _categories,
        language: language,
      );
      if (_isDisposed) return null;
      _state = VoiceState.complete;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) return null;
      _state = VoiceState.error;
    }

    if (!_isDisposed) notifyListeners();
    return _extraction;
  }

  void reset() {
    if (_isDisposed) return;
    _state = VoiceState.idle;
    _partialText = '';
    _finalText = '';
    _extraction = null;
    _errorMessage = null;
    notifyListeners();
  }

  void addNewCategories(
    BuildContext context, {
    bool Function()? isMounted,
  }) async {
    if (isMounted != null && !isMounted()) return;
    if (!context.mounted) return;

    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddNewCategories(),
    );

    if (!_isDisposed) {
      await fetchCategories();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speechService.dispose();
    _orchestrator.cancelDownload();
    super.dispose();
  }
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isAvailable;
  }

  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speech.locales();
  }

  Future<void> startListening({
    required void Function(String finalResult) onResult,
    void Function(String partial)? onPartial,
    void Function()? onDone,
    String? localeId,
  }) async {
    if (!_isAvailable) return;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else {
          onPartial?.call(result.recognizedWords);
        }
      },
      // ignore: deprecated_member_use
      listenFor: const Duration(seconds: 30),
      // ignore: deprecated_member_use
      pauseFor: const Duration(seconds: 3),
      // ignore: deprecated_member_use
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
  }
}
