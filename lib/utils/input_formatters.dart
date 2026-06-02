import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = '.';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(cleanText) ?? 0;

    final formatter = NumberFormat('#,###', 'id_ID');
    final newText = formatter.format(value).replaceAll(',', separator);

    final diff = newText.length - oldValue.text.length;
    final newOffset = (newValue.selection.end + diff).clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
