import '../../models/habit.dart';

/// One yes/no line in the report (a habit, or a single prayer sub-item).
class ReportItem {
  const ReportItem({
    required this.key,
    required this.label,
    required this.emoji,
    required this.iconCodePoint,
  });

  final String key;
  final String label;
  final String emoji;
  final int? iconCodePoint;
}

/// Flattens the daily habits into individual yes/no report items
/// (prayers expand into five items).
List<ReportItem> buildReportItems(List<Habit> dailyHabits) {
  final items = <ReportItem>[];
  for (final h in dailyHabits) {
    if (h.hasSubItems) {
      for (var i = 0; i < h.subItems.length; i++) {
        items.add(ReportItem(
          key: h.logKeys[i],
          label: '${h.name} — ${h.subItems[i]}',
          emoji: h.emoji,
          iconCodePoint: h.iconCodePoint,
        ));
      }
    } else {
      items.add(ReportItem(
        key: h.id,
        label: h.name,
        emoji: h.emoji,
        iconCodePoint: h.iconCodePoint,
      ));
    }
  }
  return items;
}
