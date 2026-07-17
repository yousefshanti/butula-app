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

const reportOpenHour = 20; // 8:00 PM
const reportCloseHour = 7; // 7:00 AM next day

/// Resolves the current report window in a user's timezone.
class ReportWindow {
  ReportWindow._({
    required this.isOpen,
    required this.reportDate,
    required this.opensAt,
  });

  final bool isOpen;

  /// The calendar day (YYYY-MM-DD) this window reports on. Always set.
  final String reportDate;

  /// When the window next opens (used for the countdown when closed).
  final DateTime opensAt;

  static ReportWindow now(tz.Location location) {
    final n = tz.TZDateTime.now(location);
    final today = tz.TZDateTime(location, n.year, n.month, n.day);

    if (n.hour >= reportOpenHour) {
      // Evening: reporting for today, window open until 7AM tomorrow.
      return ReportWindow._(
        isOpen: true,
        reportDate: dateKey(today),
        opensAt: today.add(const Duration(hours: reportOpenHour)),
      );
    }
    if (n.hour < reportCloseHour) {
      // Early morning: still reporting for yesterday.
      final yesterday = today.subtract(const Duration(days: 1));
      return ReportWindow._(
        isOpen: true,
        reportDate: dateKey(yesterday),
        opensAt: yesterday.add(const Duration(hours: reportOpenHour)),
      );
    }
    // Daytime: closed. Next open is today 8PM (reports for today).
    return ReportWindow._(
      isOpen: false,
      reportDate: dateKey(today),
      opensAt: today.add(const Duration(hours: reportOpenHour)),
    );
  }

  Duration untilOpen(tz.Location location) {
    final n = tz.TZDateTime.now(location);
    final diff = opensAt.difference(n);
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// The date key for "today" in the user's timezone (for daily logging).
String todayKey(tz.Location location) {
  final n = tz.TZDateTime.now(location);
  return dateKey(n);
}

String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}
