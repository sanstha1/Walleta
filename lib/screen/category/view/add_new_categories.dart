import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:walleta/screen/category/components/select_emoij.dart';
import 'package:walleta/screen/category/viewmodel/add_category_view_model.dart';
import 'package:walleta/theme/app_colors.dart';

class AddNewCategories extends StatelessWidget {
  const AddNewCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AddCategoryViewModel>.reactive(
      viewModelBuilder: () => AddCategoryViewModel(),
      builder: (context, model, child) {
        final colors = AppColors.of(context);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: colors.tileBG,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colors.disabled,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => model.onCancelPressed(context),
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: colors.containerBG2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'TITLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: colors.secondaryGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.containerBG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: model.titleController,
                    focusNode: model.titleFocusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => model.updateCanAddCategory(),
                    style: TextStyle(fontSize: 16, color: colors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Groceries, Travel...',
                      hintStyle: TextStyle(color: colors.disabledText),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'EMOJI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: colors.secondaryGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.containerBG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SelectEmoji(
                    emojis: model.emojis,
                    selectedEmoji: model.selectedEmoji,
                    onSelected: model.selectEmoji,
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: model.canAddCategory && !model.isBusy
                        ? () => model.onSaveCategoryPressed(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      disabledBackgroundColor: colors.disabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: model.isBusy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
