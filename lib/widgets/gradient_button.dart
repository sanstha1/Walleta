import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final IconData? icon;
  final Widget? child;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width = double.infinity,
    this.height = 57,
    this.borderRadius = 24,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.isLoading = false,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: (onPressed != null && !isLoading)
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.white.withOpacity(0.2);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.white.withOpacity(0.1);
                  }
                  return null;
                }),
              ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF01796F), Color(0xFFADADAD)],
                stops: [0.4, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              padding: padding,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : child ??
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, size: fontSize + 2),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  text,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize,
                                    fontWeight: fontWeight,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
