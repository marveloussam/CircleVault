import 'package:intl/intl.dart';

abstract class DateHelpers {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortFormat = DateFormat('dd MMM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// e.g. "23 May 2026"
  static String formatDate(DateTime dt) => _dateFormat.format(dt);

  /// e.g. "23 May 2026, 08:00 AM"
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

  /// e.g. "23 May"
  static String formatShort(DateTime dt) => _shortFormat.format(dt);

  /// e.g. "08:00 AM"
  static String formatTime(DateTime dt) => _timeFormat.format(dt);

  /// Human-friendly relative time: "just now", "2 mins ago", "yesterday", etc.
  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(dt);
  }

  /// Adds the frequency interval to a DateTime.
  /// frequency: 'weekly' | 'biweekly' | 'monthly'
  static DateTime addFrequency(DateTime from, String frequency) {
    switch (frequency) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      default:
        return from.add(const Duration(days: 30));
    }
  }

  /// Returns true if dt is today or in the past.
  static bool isDueOrPast(DateTime dt) {
    final today = DateTime.now();
    return dt.isBefore(today) ||
        (dt.year == today.year && dt.month == today.month && dt.day == today.day);
  }
}
