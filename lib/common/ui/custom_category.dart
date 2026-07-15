import 'package:flutter/material.dart';
import 'package:walleta/common/ui/custom_keyboard_hide.dart';
import 'package:walleta/theme/app_colors.dart';

class CustomCategory extends StatelessWidget {
  final String emoji;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomCategory({
    super.key,
    required this.emoji,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return CustomKeyboardHide(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.containerBG,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.primaryText,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
