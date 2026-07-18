import 'package:flutter/material.dart';

enum HabitType { daily, weekly, monthly }

extension HabitTypeX on HabitType {
  String get key => name;
  static HabitType fromKey(String? k) => HabitType.values.firstWhere(
        (e) => e.name == k,
        orElse: () => HabitType.daily,
      );
}

/// Schedule for weekly/monthly habits. Unused fields are null.
class HabitSchedule {
  const HabitSchedule({
    this.weekdays = const [],
    this.timesPerWeek,
    this.dayOfMonth,
    this.timesPerMonth,
  });

  /// 1 = Monday .. 7 = Sunday (DateTime.weekday convention).
  final List<int> weekdays;
  final int? timesPerWeek;
  final int? dayOfMonth;
  final int? timesPerMonth;

  Map<String, dynamic> toMap() => {
        'weekdays': weekdays,
        'timesPerWeek': timesPerWeek,
        'dayOfMonth': dayOfMonth,
        'timesPerMonth': timesPerMonth,
      };

  factory HabitSchedule.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const HabitSchedule();
    return HabitSchedule(
      weekdays: (m['weekdays'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
      timesPerWeek: (m['timesPerWeek'] as num?)?.toInt(),
      dayOfMonth: (m['dayOfMonth'] as num?)?.toInt(),
      timesPerMonth: (m['timesPerMonth'] as num?)?.toInt(),
    );
  }

  HabitSchedule copyWith({
    List<int>? weekdays,
    int? timesPerWeek,
    int? dayOfMonth,
    int? timesPerMonth,
    bool clearWeekdays = false,
  }) =>
      HabitSchedule(
        weekdays: clearWeekdays ? const [] : (weekdays ?? this.weekdays),
        timesPerWeek: timesPerWeek ?? this.timesPerWeek,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        timesPerMonth: timesPerMonth ?? this.timesPerMonth,
      );
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.emoji = '⭐',
    this.iconCodePoint,
    this.points = 0,
    this.type = HabitType.daily,
    this.schedule = const HabitSchedule(),
    this.reminderEnabled = false,
    this.reminderMinutes,
    this.isPrivate = false,
    this.order = 0,
    this.subItems = const [],
    this.deleted = false,
  });

  final String id;
  final String name;
  final String emoji;

  /// If set, render a Material icon instead of [emoji].
  final int? iconCodePoint;

  /// User-defined weight. For daily habits, all daily weights must sum to 100.
  final int points;
  final HabitType type;
  final HabitSchedule schedule;
  final bool reminderEnabled;

  /// Minutes from midnight (0..1439), local time. Null when no reminder.
  final int? reminderMinutes;
  final bool isPrivate;
  final int order;

  /// Named sub-items (e.g. the five prayers). Empty for a normal habit.
  final List<String> subItems;

  /// Soft-delete flag: kept in Firestore so history/export survives deletion,
  /// but filtered out of the active habit list everywhere in the app.
  final bool deleted;

  bool get hasSubItems => subItems.isNotEmpty;
  bool get isDaily => type == HabitType.daily;

  /// Log/report keys this habit contributes. A plain habit has one key (its id);
  /// a habit with sub-items has one key per sub-item.
  List<String> get logKeys => hasSubItems
      ? List.generate(subItems.length, (i) => '$id::$i')
      : [id];

  TimeOfDay? get reminderTime => reminderMinutes == null
      ? null
      : TimeOfDay(hour: reminderMinutes! ~/ 60, minute: reminderMinutes! % 60);

  /// Points earned given the set of completed log keys.
  int scoreFor(Set<String> doneKeys) {
    if (isPrivate) return 0;
    if (!hasSubItems) return doneKeys.contains(id) ? points : 0;
    final doneCount = logKeys.where(doneKeys.contains).length;
    return ((points * doneCount) / subItems.length).round();
  }

  Habit copyWith({
    String? id,
    String? name,
    String? emoji,
    int? iconCodePoint,
    bool clearIcon = false,
    int? points,
    HabitType? type,
    HabitSchedule? schedule,
    bool? reminderEnabled,
    int? reminderMinutes,
    bool clearReminder = false,
    bool? isPrivate,
    int? order,
    List<String>? subItems,
    bool? deleted,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        iconCodePoint: clearIcon ? null : (iconCodePoint ?? this.iconCodePoint),
        points: points ?? this.points,
        type: type ?? this.type,
        schedule: schedule ?? this.schedule,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderMinutes:
            clearReminder ? null : (reminderMinutes ?? this.reminderMinutes),
        isPrivate: isPrivate ?? this.isPrivate,
        order: order ?? this.order,
        subItems: subItems ?? this.subItems,
        deleted: deleted ?? this.deleted,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'iconCodePoint': iconCodePoint,
        'points': points,
        'type': type.key,
        'schedule': schedule.toMap(),
        'reminderEnabled': reminderEnabled,
        'reminderTime': reminderMinutes,
        'isPrivate': isPrivate,
        'order': order,
        'subItems': subItems,
        'deleted': deleted,
      };

  factory Habit.fromMap(String id, Map<String, dynamic> m) => Habit(
        id: id,
        name: (m['name'] ?? '') as String,
        emoji: (m['emoji'] ?? '⭐') as String,
        iconCodePoint: (m['iconCodePoint'] as num?)?.toInt(),
        points: (m['points'] as num?)?.toInt() ?? 0,
        type: HabitTypeX.fromKey(m['type'] as String?),
        schedule: HabitSchedule.fromMap(
            (m['schedule'] as Map?)?.cast<String, dynamic>()),
        reminderEnabled: (m['reminderEnabled'] as bool?) ?? false,
        reminderMinutes: (m['reminderTime'] as num?)?.toInt(),
        isPrivate: (m['isPrivate'] as bool?) ?? false,
        order: (m['order'] as num?)?.toInt() ?? 0,
        subItems: (m['subItems'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        deleted: (m['deleted'] as bool?) ?? false,
      );
}

/// Stable notification id derived from a habit id (for per-habit reminders).
int habitNotificationId(String habitId) {
  var h = 0;
  for (final c in habitId.codeUnits) {
    h = (h * 31 + c) & 0x3FFFFFFF;
  }
  // Keep away from the reserved report reminder ids (0, 1).
  return 1000 + (h % 1000000);
}
