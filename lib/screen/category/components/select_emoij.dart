import 'package:flutter/material.dart';
import 'package:walleta/theme/app_colors.dart';

class SelectEmoji extends StatelessWidget {
  final List<String> emojis;
  final String selectedEmoji;
  final ValueChanged<String> onSelected;

  const SelectEmoji({
    super.key,
    required this.emojis,
    required this.selectedEmoji,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final isSelected = selectedEmoji == emoji;

        return GestureDetector(
          onTap: () => onSelected(emoji),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withOpacity(0.15)
                  : colors.containerBG2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
        );
      },
    );
  }
}
