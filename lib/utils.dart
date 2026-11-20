import 'package:intl/intl.dart';

class AppUtils {
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} ${AppConstants.currency}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String cleanMoroccanPhone(String input) {
    String p = input.replaceAll(RegExp(r'\s+'), '');
    if (p.startsWith('0')) {
      p = '212${p.substring(1)}';
    } else if (p.startsWith('+212')) {
      p = p.substring(1);
    }
    return p;
  }
}