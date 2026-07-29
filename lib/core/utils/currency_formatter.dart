import 'package:intl/intl.dart';

abstract class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  /// Formats an integer kobo amount to a display string e.g. ₦5,000.00
  static String format(int kobo) {
    final naira = kobo / 100.0;
    return _formatter.format(naira);
  }

  /// Formats kobo as compact string e.g. ₦5k, ₦1.2M
  static String formatCompact(int kobo) {
    final naira = kobo / 100.0;
    if (naira >= 1000000) {
      return '₦${(naira / 1000000).toStringAsFixed(1)}M';
    } else if (naira >= 1000) {
      return '₦${(naira / 1000).toStringAsFixed(1)}k';
    }
    return '₦${naira.toStringAsFixed(0)}';
  }

  /// Converts a Naira double to kobo integer (multiply by 100).
  static int toKobo(double naira) => (naira * 100).round();

  /// Converts a Naira integer string to kobo (e.g. "5000" → 500000).
  static int nairaStringToKobo(String nairaString) {
    final parsed = double.tryParse(nairaString.trim()) ?? 0;
    return toKobo(parsed);
  }

  /// Converts kobo to Naira double.
  static double toNaira(int kobo) => kobo / 100.0;
}
