import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walleta/common/ui/custom_category.dart';
import 'package:walleta/common/ui/custom_gradient_button.dart';
import 'package:walleta/common/ui/custom_ui_helper.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';
import 'package:walleta/screen/voice/components/transaction_text_field.dart';
import 'package:walleta/theme/app_colors.dart';

class TransactionConfirmationForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final List<Category> categories;
  final String selectedCategory;
  final bool isIncome;
  final bool busy;
  final bool canSave;
  final String transcribedText;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<bool> onSignChanged;
  final VoidCallback onSave;
  final VoidCallback onTryAgain;
  final VoidCallback onAddCategory;

  const TransactionConfirmationForm({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.categories,
    required this.selectedCategory,
    required this.isIncome,
    required this.busy,
    required this.canSave,
    required this.transcribedText,
    required this.onCategorySelected,
    required this.onSignChanged,
    required this.onSave,
    required this.onTryAgain,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: lXPadding,
            child: Container(
              width: double.infinity,
              padding: mPadding,
              decoration: BoxDecoration(
                color: AppColors.of(context).containerBG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You Said",
                    style: bodySmall(context)?.copyWith(
                      color: AppColors.of(
                        context,
                      ).primaryText.withValues(alpha: 0.6),
                    ),
                  ),
                  xxsHSpan,
                  Text(
                    '"$transcribedText"',
                    style: bodyMedium(
                      context,
                    )?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          xlHSpan,

          TransactionTextField(
            hintText: "Title",
            controller: titleController,
            textInputAction: TextInputAction.next,
          ),
          sHSpan,

          TransactionTextField(
            keyboardType: TextInputType.number,
            hintText: "Amount",
            prefixEnabled: true,
            suffixEnabled: true,
            controller: amountController,
            initialSign: isIncome,
            onSignChanged: onSignChanged,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          xlHSpan,

          Padding(
            padding: lXPadding,
            child: Text("My Categories", style: bodyMediumB(context)),
          ),
          mHSpan,
          SingleChildScrollView(
            padding: lXPadding,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: onAddCategory,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1.2,
                          color: AppColors.of(context).primary,
                        ),
                      ),
                      child: Padding(
                        padding: xsPadding,
                        child: Icon(
                          Icons.add,
                          color: AppColors.of(context).primary,
                        ),
                      ),
                    ),
                  ),
                ),
                ...categories.map((category) {
                  final title = category.title;
                  final emoji = category.emoji;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CustomCategory(
                      emoji: emoji,
                      text: title,
                      isSelected: selectedCategory == title,
                      onTap: () => onCategorySelected(title),
                    ),
                  );
                }),
              ],
            ),
          ),
          xlHSpan,

          Padding(
            padding: lXPadding,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onTryAgain,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.of(
                            context,
                          ).primaryText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text("Try Again", style: bodyMediumB(context)),
                      ),
                    ),
                  ),
                ),
                mWSpan,
                Expanded(
                  child: CustomGradientButton(
                    disabledColor: AppColors.of(context).tileBG,
                    busy: busy,
                    borderRadius: 30,
                    onPressed: canSave ? onSave : null,
                    buttonLabel: "Save",
                  ),
                ),
              ],
            ),
          ),
          xxlHSpan,
        ],
      ),
    );
  }
}
