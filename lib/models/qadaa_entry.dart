/// A missed prayer tracked for make-up (قضاء). Private to the user; never
/// affects leaderboard points or the daily 100.
class QadaaEntry {
  const QadaaEntry({
    required this.id,
    required this.prayerKey,
    required this.missedDate,
    this.madeUpDate,
  });

  final String id;

  /// The prayer's name (e.g. الفجر) — used for grouping and counts.
  final String prayerKey;

  /// The day the prayer was missed (YYYY-MM-DD).
  final String missedDate;

  /// The day it was made up (YYYY-MM-DD), or null while still pending.
  final String? madeUpDate;

  bool get isPending => madeUpDate == null;

  Map<String, dynamic> toMap() => {
        'prayerKey': prayerKey,
        'missedDate': missedDate,
        'madeUpDate': madeUpDate,
      };

  factory QadaaEntry.fromMap(String id, Map<String, dynamic> m) => QadaaEntry(
        id: id,
        prayerKey: (m['prayerKey'] ?? '') as String,
        missedDate: (m['missedDate'] ?? '') as String,
        madeUpDate: m['madeUpDate'] as String?,
      );
}
