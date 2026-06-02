import 'package:intl/intl.dart';

class CurrencyFormat {
  static String convertToIdr(num? number, int decimalDigit) {
    final value = number ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: decimalDigit,
    );
    return formatter.format(value);
  }

  static int parseIdr(String formattedString) {
    final clean = formattedString
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return int.tryParse(clean) ?? 0;
  }
}
