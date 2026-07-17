import '../../core/date_utils.dart';
import '../../models/daily_log.dart';
import '../../models/daily_report.dart';
import '../../models/habit.dart';

enum StatsRange { week, month, threeMonths, all }

extension StatsRangeX on StatsRange {
  int get days => switch (this) {
        StatsRange.week => 7,
        StatsRange.month => 30,
        StatsRange.threeMonths => 90,
        StatsRange.all => 730,
      };
}

/// Per-day completion fraction of a habit: 0..1.
/// Plain habit -> 0 or 1; prayers/sub-items -> doneCount / total.
double dayFraction(Habit habit, DailyLog log) {
  final keys = habit.logKeys;
  if (keys.isEmpty) return 0;
  final done = keys.where(log.doneKeys.contains).length;
  return done / keys.length;
}

class DaySeriesPoint {
  const DaySeriesPoint(this.date, this.value);
  final DateTime date;
  final double value;
}

class HabitStats {
  const HabitStats({
    required this.completionPct,
    required this.currentStreak,
    required this.longestStreak,
    required this.series,
  });
  final double completionPct;
  final int currentStreak;
  final int longestStreak;
  final List<DaySeriesPoint> series;
}

List<DateTime> _daysBetween(DateTime start, DateTime end) {
  final days = <DateTime>[];
  var d = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!d.isAfter(last)) {
    days.add(d);
    d = d.add(const Duration(days: 1));
  }
  return days;
}

HabitStats computeHabitStats(
  Habit habit,
  Map<String, DailyLog> logs,
  DateTime start,
  DateTime end,
) {
  final days = _daysBetween(start, end);
  final series = <DaySeriesPoint>[];
  final done = <bool>[];
  var sum = 0.0;
  for (final d in days) {
    final log = logs[dateKey(d)];
    final f = log == null ? 0.0 : dayFraction(habit, log);
    series.add(DaySeriesPoint(d, f));
    done.add(f >= 1.0);
    sum += f;
  }

  final pct = days.isEmpty ? 0.0 : (sum / days.length) * 100;

  var longest = 0;
  var run = 0;
  for (final isDone in done) {
    if (isDone) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  var current = 0;
  for (var i = done.length - 1; i >= 0; i--) {
    if (done[i]) {
      current++;
    } else {
      break;
    }
  }

  return HabitStats(
    completionPct: pct,
    currentStreak: current,
    longestStreak: longest,
    series: series,
  );
}

class GeneralStats {
  const GeneralStats({
    required this.scores,
    required this.dailyAverage,
    required this.bestDay,
    required this.reportedDays,
  });
  final List<DaySeriesPoint> scores;
  final double dailyAverage;
  final int bestDay;
  final int reportedDays;
}

GeneralStats computeGeneralStats(
  Map<String, DailyReport> reports,
  DateTime start,
  DateTime end,
) {
  final days = _daysBetween(start, end);
  final scores = <DaySeriesPoint>[];
  var sum = 0;
  var reported = 0;
  var best = 0;
  for (final d in days) {
    final r = reports[dateKey(d)];
    final score = r?.totalPoints ?? 0;
    scores.add(DaySeriesPoint(d, score.toDouble()));
    if (r != null && r.isCertified) {
      sum += score;
      reported++;
      if (score > best) best = score;
    }
  }
  final avg = reported == 0 ? 0.0 : sum / reported;
  return GeneralStats(
    scores: scores,
    dailyAverage: avg,
    bestDay: best,
    reportedDays: reported,
  );
}
