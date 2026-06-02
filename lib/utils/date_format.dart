import 'package:intl/intl.dart';

class DateFormatHelper {
  /// Format: 31-12-2023
  static String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Format: 31-12-2023 14:30
  static String formatDateTime(DateTime date) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date);
  }

  /// Format: Senin, 31 Desember 2023
  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }
}
