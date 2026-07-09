import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:walleta/screen/category/components/add_category.dart';
import 'package:walleta/screen/category/view/add_new_categories.dart';
import 'package:walleta/screen/category/viewmodel/add_category_view_model.dart';
import 'package:walleta/theme/app_colors.dart';

class ShowNewCategoriesScreen extends StatelessWidget {
  const ShowNewCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AddCategoryViewModel>.reactive(
      viewModelBuilder: () => AddCategoryViewModel(),
      onViewModelReady: (model) => model.fetchCategories(),
      builder: (context, model, child) {
        final colors = AppColors.of(context);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: colors.tileBG,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colors.disabled,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AddNewCategories(),
                        );
                        if (result == true) model.fetchCategories();
                      },
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (model.isBusy)
                  const Center(child: CircularProgressIndicator())
                else if (model.categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No categories yet',
                      style: TextStyle(color: colors.disabledText),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: model.categories.map((category) {
                      return AddCategory(
                        emoji: category.emoji,
                        title: category.title,
                        isSelected: false,
                        onTap: () {},
                        onLongPress: category.isCustom
                            ? () => _confirmDelete(context, model, category)
                            : null,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    AddCategoryViewModel model,
    CategoryModel category,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove "${category.title}" from your categories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              model.deleteCategory(category.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
