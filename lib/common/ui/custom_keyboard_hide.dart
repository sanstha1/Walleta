import 'package:flutter/material.dart';

class CustomKeyboardHide extends StatelessWidget {
  final Widget child;

  const CustomKeyboardHide({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
