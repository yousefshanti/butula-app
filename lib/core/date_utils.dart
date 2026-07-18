import 'package:timezone/timezone.dart' as tz;

/// Formats a DateTime as a YYYY-MM-DD key.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String monthKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// The app's "day" starts at 3:00 AM local time (fixed, no prayer-time calc).
/// e.g. at 1:30 AM on Jul 19 the app-day is still Jul 18.
const appDayBoundaryHour = 3;
const reportOpenHour = 20; // 8:00 PM — report window opens
const reportCloseHour = appDayBoundaryHour; // 3:00 AM — window closes (day end)

/// The app-day key for a given instant, applying the 3 AM boundary.
String appDayKeyOf(DateTime instant) =>
    dateKey(instant.subtract(const Duration(hours: appDayBoundaryHour)));

/// The current app-day key in the user's timezone (used for daily logging).
String todayKey(tz.Location location) =>
    appDayKeyOf(tz.TZDateTime.now(location));

/// The current app-month key (YYYY-MM), based on the app-day.
String currentAppMonthKey(tz.Location location) =>
    monthKeyOf(parseDateKey(todayKey(location)));

/// Resolves the current report window (8:00 PM → 3:00 AM) in a user's timezone.
class ReportWindow {
  ReportWindow._({
    required this.isOpen,
    required this.reportDate,
    required this.opensAt,
  });

  final bool isOpen;

  /// The app-day (YYYY-MM-DD) this window reports on. Always set.
  final String reportDate;

  /// When the window next opens (used for the countdown when closed).
  final DateTime opensAt;

  static ReportWindow now(tz.Location location) {
    final n = tz.TZDateTime.now(location);
    final appDay = appDayKeyOf(n);
    final appDate = parseDateKey(appDay);
    // 8:00 PM on the app-day's calendar date.
    final opensAt = tz.TZDateTime(
      location,
      appDate.year,
      appDate.month,
      appDate.day,
      reportOpenHour,
    );
    // Open during 8PM..midnight and midnight..3AM (the tail of the app-day).
    final isOpen = n.hour >= reportOpenHour || n.hour < appDayBoundaryHour;
    return ReportWindow._(isOpen: isOpen, reportDate: appDay, opensAt: opensAt);
  }

  Duration untilOpen(tz.Location location) {
    final n = tz.TZDateTime.now(location);
    final diff = opensAt.difference(n);
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// Shifts a YYYY-MM-DD key by [days].
String shiftDayKey(String key, int days) =>
    dateKey(parseDateKey(key).add(Duration(days: days)));

const _arWeekdays = [
  'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
];
const _arMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
const _enWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _toArabicDigits(String s) => s.replaceAllMapped(
    RegExp(r'[0-9]'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);

/// A friendly weekday + day + month label, e.g. "الجمعة ١٧ يوليو".
String dayLabel(String key, {required bool isArabic}) {
  final d = parseDateKey(key);
  if (isArabic) {
    return '${_arWeekdays[d.weekday - 1]} '
        '${_toArabicDigits(d.day.toString())} ${_arMonths[d.month - 1]}';
  }
  return '${_enWeekdays[d.weekday - 1]} ${d.day} ${_enMonths[d.month - 1]}';
}

/// A long date, e.g. "١٧ يوليو ٢٠٢٦" (Arabic) or "17 July 2026" (English).
String longDate(DateTime d, {required bool isArabic}) {
  if (isArabic) {
    return '${_toArabicDigits(d.day.toString())} ${_arMonths[d.month - 1]} '
        '${_toArabicDigits(d.year.toString())}';
  }
  return '${d.day} ${_enMonths[d.month - 1]} ${d.year}';
}

String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}
