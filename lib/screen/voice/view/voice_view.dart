import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/common/ui/custom_gradient_button.dart';
import 'package:walleta/common/ui/custom_loader.dart';
import 'package:walleta/common/ui/custom_ui_helper.dart';
import 'package:walleta/screen/chart/view/chart_view.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';
import 'package:walleta/screen/text_transaction/viewmodel/get_transaction_view_model.dart';
import 'package:walleta/screen/voice/components/model_download_widget.dart';
import 'package:walleta/screen/voice/components/voice_listening_indicator.dart';
import 'package:walleta/screen/voice/viewmodel/record_voice_view_model.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:stacked/stacked.dart';

const Color _accentTeal = Color(0xFF006A60);

@RoutePage()
class RecordVoiceView extends StatefulWidget {
  final VoidCallback? onAdded;

  const RecordVoiceView({super.key, this.onAdded});

  @override
  State<RecordVoiceView> createState() => _RecordVoiceViewState();
}

class _RecordVoiceViewState extends State<RecordVoiceView> {
  late final GetTransactionViewModel _getViewModel;
  late final AddTransactionViewModel _addViewModel;

  @override
  void initState() {
    super.initState();
    _getViewModel = GetTransactionViewModel()..initialize();
    _addViewModel = AddTransactionViewModel()..fetchCategories();
  }

  @override
  void dispose() {
    _getViewModel.dispose();
    _addViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _getViewModel),
        ChangeNotifierProvider.value(value: _addViewModel),
      ],
      child: ViewModelBuilder<RecordVoiceViewModel>.reactive(
        viewModelBuilder: () => RecordVoiceViewModel(),
        onViewModelReady: (model) => model.initialize(),
        builder: (context, model, child) {
          return Scaffold(
            backgroundColor: colors.backgroundColor,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                TransactionPage.showAddTransactionModal(
                  context,
                  _addViewModel,
                  _getViewModel,
                );
              },
              backgroundColor: _accentTeal,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Add",
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.only(bottom: 100),
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(context, model),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RecordVoiceViewModel model) {
    switch (model.state) {
      case VoiceState.idle:
        return _buildIdleState(context, model);
      case VoiceState.listening:
        return _buildListeningState(context, model);
      case VoiceState.processing:
        return _buildProcessingState(context);
      case VoiceState.error:
        return _buildErrorState(context, model);
      case VoiceState.complete:
        return _buildCompleteState(context, model);
    }
  }

  Widget _buildCompleteState(BuildContext context, RecordVoiceViewModel model) {
    final colors = AppColors.of(context);
    final transaction = model.extraction;

    if (transaction == null) return _buildIdleState(context, model);

    _addViewModel.transactionTitle.text = transaction.title ?? '';
    _addViewModel.transactionAmount.text = transaction.amount?.toString() ?? '';
    _addViewModel.onSignChange(transaction.isIncome ?? false);
    _addViewModel.selectCategory(transaction.categoryTitle ?? '');

    final currencySymbol = model.isNepali ? 'रु' : '\$';

    return Column(
      key: const ValueKey('complete'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "You said: ${model.finalText}",
          style: TextStyle(fontFamily: 'monospace', color: colors.primaryText),
        ),
        Divider(height: 24, color: colors.disabledText.withValues(alpha: 0.2)),
        Text(
          "Amount: $currencySymbol${transaction.amount?.toStringAsFixed(2) ?? ''}",
          style: TextStyle(fontFamily: 'monospace', color: colors.primaryText),
        ),
        Text(
          "Title: ${transaction.title ?? ''}",
          style: TextStyle(fontFamily: 'monospace', color: colors.primaryText),
        ),
        if (transaction.categoryTitle != null)
          Text(
            "Category: ${transaction.categoryTitle}",
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.primaryText,
            ),
          ),
        Text(
          "Type: ${transaction.isIncome == true ? 'Income' : 'Expense'}",
          style: TextStyle(fontFamily: 'monospace', color: colors.primaryText),
        ),
        Divider(height: 24, color: colors.disabledText.withValues(alpha: 0.2)),
        Padding(
          padding: lXPadding,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => model.changeState(VoiceState.idle),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: colors.primaryText.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              mWSpan,
              Expanded(
                child: CustomGradientButton(
                  buttonLabel: "Add Transaction",
                  onPressed: () {
                    model.changeState(VoiceState.idle);
                    TransactionPage.showAddTransactionModal(
                      context,
                      _addViewModel,
                      _getViewModel,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState(BuildContext context, RecordVoiceViewModel model) {
    final colors = AppColors.of(context);
    return Column(
      key: const ValueKey('idle'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        GestureDetector(
          onTap: model.toggleLanguage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _accentTeal, width: 1.2),
              color: colors.containerBG,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  model.isNepali ? '🇳🇵' : '🇬🇧',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  model.isNepali ? 'नेपाली' : 'English',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    color: _accentTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: _accentTeal,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        xlHSpan,
        VoiceListeningIndicator(isListening: false, onTap: model.onMicPressed),
        xlHSpan,
        Text(
          "Tap to Speak",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.primaryText,
          ),
        ),
        sHSpan,
        Padding(
          padding: xlXPadding,
          child: Text(
            model.isNepali
                ? '"मैले खानामा ५०० रुपैयाँ खर्च गरें"'
                : '"I spent \$10 on groceries"',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: colors.primaryText.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        xlHSpan,
        ModelDownloadWidget(
          isModelLoaded: model.isModelLoaded,
          isDownloading: model.isDownloading,
          downloadProgress: model.downloadProgress,
          onDownload: model.downloadAiModel,
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildListeningState(
    BuildContext context,
    RecordVoiceViewModel model,
  ) {
    final colors = AppColors.of(context);
    return Column(
      key: const ValueKey('listening'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        if (model.partialText.isNotEmpty) ...[
          Padding(
            padding: xlXPadding,
            child: Text(
              model.partialText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 17,
                color: colors.primaryText.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          xlHSpan,
        ],
        VoiceListeningIndicator(isListening: true, onTap: model.onMicPressed),
        xlHSpan,
        Text(
          "Listening",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _accentTeal,
          ),
        ),
        sHSpan,
        Text(
          model.isNepali ? '🇳🇵 नेपालीमा बोल्नुस्' : '🇬🇧 Speak in English',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: colors.primaryText.withValues(alpha: 0.4),
          ),
        ),
        sHSpan,
        Text(
          "Tap to Stop",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: colors.primaryText.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      key: const ValueKey('processing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        CustomLoader.minimal(foreground: _accentTeal),
        lHSpan,
        Text(
          "Processing Voice",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            color: colors.primaryText.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, RecordVoiceViewModel model) {
    final colors = AppColors.of(context);
    return Column(
      key: const ValueKey('error'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Icon(Icons.error_outline_rounded, size: 64, color: colors.warning),
        lHSpan,
        Padding(
          padding: xlXPadding,
          child: Text(
            model.errorMessage ?? "Something went wrong",
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        xlHSpan,
        GestureDetector(
          onTap: model.reset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: AppColors.tealGradient,
            ),
            child: Text(
              "Try Again",
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: colors.solidBlack,
              ),
            ),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}
