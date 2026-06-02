import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  // ====================
  // Properties
  // ====================

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isCurrency;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? hintText;
  final int? maxLines;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool showLabel;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? borderWidth;

  // ====================
  // Constructor
  // ====================

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.isCurrency = false,
    this.readOnly = false,
    this.onTap,
    this.hintText,
    this.maxLines = 1,
    this.obscureText = false,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.contentPadding,
    this.borderRadius,
    this.suffixIcon,
    this.prefixIcon,
    this.showLabel = true,
    this.labelStyle,
    this.hintStyle,
    this.borderColor,
    this.focusedBorderColor,
    this.borderWidth,
  });

  // ====================
  // Build Method
  // ====================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) _buildLabel(context),
        if (showLabel) const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          inputFormatters: _getInputFormatters(),
          decoration: _buildInputDecoration(context),
        ),
      ],
    );
  }

  // ====================
  // Private Helpers
  // ====================

  Widget _buildLabel(BuildContext context) {
    return Text(
      label,
      style:
          labelStyle ??
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final defaultContentPadding =
        contentPadding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return InputDecoration(
      hintText: _getHintText(),
      hintStyle:
          hintStyle ?? TextStyle(color: theme.hintColor.withOpacity(0.7)),
      prefixText: isCurrency ? 'Rp ' : null,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: _buildBorder(
        defaultBorderRadius,
        color: borderColor ?? theme.dividerColor,
        width: borderWidth ?? 1.0,
      ),
      enabledBorder: _buildBorder(
        defaultBorderRadius,
        color: borderColor ?? theme.dividerColor,
        width: borderWidth ?? 1.0,
      ),
      focusedBorder: _buildBorder(
        defaultBorderRadius,
        color: focusedBorderColor ?? theme.primaryColor,
        width: borderWidth != null ? borderWidth! + 0.5 : 1.5,
      ),
      filled: readOnly,
      fillColor: readOnly ? theme.disabledColor.withOpacity(0.1) : null,
      contentPadding: defaultContentPadding,
      errorMaxLines: 2,
    );
  }

  OutlineInputBorder _buildBorder(
    BorderRadius borderRadius, {
    required Color color,
    required double width,
  }) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String _getHintText() {
    if (hintText != null) return hintText!;
    return isCurrency ? '0' : 'Masukkan $label';
  }

  List<TextInputFormatter>? _getInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (inputFormatters != null) {
      formatters.addAll(inputFormatters!);
    }

    if (isCurrency) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    return formatters.isNotEmpty ? formatters : null;
  }
}
