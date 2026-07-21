import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.##');

  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String number(double value) {
    return _decimalFormatter.format(value);
  }

  static String quantityWithUnit(double qty, String unit) {
    final formattedNumber = number(qty);
    return '$formattedNumber $unit';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
