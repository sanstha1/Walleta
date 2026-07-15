import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/theme/app_colors.dart';

class TransactionTextField extends StatefulWidget {
  final String? hintText;
  final TextStyle? labelStyle;
  final String? labelText;
  final TextStyle? hintStyle;
  final TextStyle? inputTextStyle;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool prefixEnabled;
  final bool suffixEnabled;
  final ValueChanged<bool>? onSignChanged;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final String? initialValue;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool initialSign;

  const TransactionTextField({
    super.key,
    this.hintText,
    this.labelStyle,
    this.labelText,
    this.hintStyle,
    this.inputTextStyle,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixEnabled = false,
    this.suffixEnabled = false,
    this.onSignChanged,
    this.focusNode,
    this.onChanged,
    this.initialValue,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.initialSign = false,
  });

  @override
  State<TransactionTextField> createState() => _TransactionTextFieldState();
}

class _TransactionTextFieldState extends State<TransactionTextField> {
  bool _isPositive = false;

  @override
  void initState() {
    super.initState();
    _isPositive = widget.initialSign;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currencySymbol = context.watch<CurrencyProvider>().symbol;
    final inputColor = _isPositive ? colors.success : colors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            widget.labelText ?? "",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        TextFormField(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onChanged: (value) {
            widget.onChanged?.call(value);
            setState(() {});
          },
          onFieldSubmitted: widget.onFieldSubmitted,
          cursorColor: colors.primaryText,
          cursorHeight: 30,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          style:
              widget.inputTextStyle?.copyWith(
                color: widget.suffixEnabled ? inputColor : colors.primaryText,
              ) ??
              TextStyle(
                color: widget.suffixEnabled ? inputColor : colors.primaryText,
                fontSize: widget.suffixEnabled ? 30 : 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputFill,
            hintText: widget.hintText,
            hintStyle:
                widget.hintStyle ??
                TextStyle(
                  color: colors.primaryText.withValues(alpha: 0.35),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
            prefixIcon: widget.prefixEnabled
                ? _buildCurrencyPrefix(context, currencySymbol)
                : null,
            suffixIcon: widget.suffixEnabled
                ? _buildToggleSuffix(context)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPrefix(BuildContext context, String symbol) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSuffix(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context: context,
            icon: Icons.remove,
            isSelected: !_isPositive,
            activeColor: colors.error,
            onTap: () {
              setState(() => _isPositive = false);
              widget.onSignChanged?.call(false);
            },
          ),
          _buildToggleButton(
            context: context,
            icon: Icons.add,
            isSelected: _isPositive,
            activeColor: colors.success,
            onTap: () {
              setState(() => _isPositive = true);
              widget.onSignChanged?.call(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? activeColor
              : colors.primaryText.withValues(alpha: 0.08),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? colors.solidBlack : colors.primaryText,
        ),
      ),
    );
  }
}
