/// A single day's habit log. Keys are habit log-keys (habitId or "habitId::i").
class DailyLog {
  const DailyLog({
    required this.date,
    this.values = const {},
    this.editedLater = false,
  });

  final String date; // YYYY-MM-DD
  final Map<String, bool> values;
  final bool editedLater;

  Set<String> get doneKeys =>
      values.entries.where((e) => e.value).map((e) => e.key).toSet();

  bool isDone(String key) => values[key] ?? false;

  DailyLog withValue(String key, bool value, {bool markEdited = false}) {
    final next = Map<String, bool>.from(values)..[key] = value;
    return DailyLog(
      date: date,
      values: next,
      editedLater: editedLater || markEdited,
    );
  }

  Map<String, dynamic> toMap() => {
        ...values,
        'editedLater': editedLater,
      };

  factory DailyLog.fromMap(String date, Map<String, dynamic> m) {
    final values = <String, bool>{};
    for (final e in m.entries) {
      if (e.key == 'editedLater') continue;
      if (e.value is bool) values[e.key] = e.value as bool;
    }
    return DailyLog(
      date: date,
      values: values,
      editedLater: (m['editedLater'] as bool?) ?? false,
    );
  }

  factory DailyLog.empty(String date) => DailyLog(date: date);
}
