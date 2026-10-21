import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final DateFormat standardDateFormat = DateFormat('d/M/yyyy');
  static final DateFormat displayDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat fullDateTimeFormat = DateFormat('MMM d, yyyy - hh:mm a');

  /// Formats [date] to "d/M/yyyy" (e.g. "15/6/2024").
  static String formatStandard(DateTime date) {
    return standardDateFormat.format(date);
  }

  /// Formats [date] to "MMM d, yyyy" (e.g. "Jun 15, 2024").
  static String formatDisplay(DateTime date) {
    return displayDateFormat.format(date);
  }

  /// Formats [date] to "MMM d, yyyy - hh:mm a".
  static String formatFull(DateTime date) {
    return fullDateTimeFormat.format(date);
  }

  /// Parses string into [DateTime], supporting both ISO-8601 and "d/M/yyyy" format.
  static DateTime? tryParse(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        return standardDateFormat.parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  /// Returns true if [dueDate] has passed and the item is not returned.
  static bool isOverdue(DateTime dueDate, [DateTime? returnedAt]) {
    if (returnedAt != null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  /// Calculates days remaining or days overdue.
  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference;
  }
}
