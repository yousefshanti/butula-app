import '../models/habit.dart';

/// Names of the five daily prayers (sub-items of the prayers habit).
const prayerNames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

class SuggestedHabit {
  const SuggestedHabit({
    required this.name,
    required this.emoji,
    required this.defaultPoints,
    this.type = HabitType.daily,
    this.subItems = const [],
    this.isPrivate = false,
  });

  final String name;
  final String emoji;
  final int defaultPoints;
  final HabitType type;
  final List<String> subItems;
  final bool isPrivate;

  Habit toHabit(String id, int order) => Habit(
        id: id,
        name: name,
        emoji: emoji,
        points: defaultPoints,
        type: type,
        subItems: subItems,
        isPrivate: isPrivate,
        order: order,
      );
}

/// Suggested habits the user can pick from to speed up setup.
/// Each is pre-filled with an emoji; the user still adjusts the weight.
const suggestedHabits = <SuggestedHabit>[
  SuggestedHabit(
    name: 'الصلوات الخمس',
    emoji: '🕌',
    defaultPoints: 30,
    subItems: prayerNames,
  ),
  SuggestedHabit(name: 'ورد القرآن', emoji: '📖', defaultPoints: 15),
  SuggestedHabit(name: 'أذكار الصباح', emoji: '🌅', defaultPoints: 8),
  SuggestedHabit(name: 'أذكار المساء', emoji: '🌜', defaultPoints: 8),
  SuggestedHabit(name: 'المذاكرة أو العمل', emoji: '💼', defaultPoints: 10),
  SuggestedHabit(name: 'قراءة كتاب', emoji: '📚', defaultPoints: 5),
  SuggestedHabit(name: 'ترتيب السرير', emoji: '🛏️', defaultPoints: 3),
  SuggestedHabit(name: 'ورد ما قبل النوم', emoji: '🌙', defaultPoints: 4),
  SuggestedHabit(name: 'الرياضة', emoji: '🏃', defaultPoints: 7),
  SuggestedHabit(name: 'قيام الليل', emoji: '🌃', defaultPoints: 5),
  SuggestedHabit(name: 'ركعة الوتر', emoji: '🕋', defaultPoints: 3),
  SuggestedHabit(name: 'اليوميات', emoji: '✍️', defaultPoints: 2),
  SuggestedHabit(name: 'الامتناع عن التصفح', emoji: '📵', defaultPoints: 5),
];

/// Private, no-points tracking items (never visible to others, excluded from totals).
const suggestedPrivateItems = <SuggestedHabit>[
  SuggestedHabit(
    name: 'الامتناع عن المحتوى الإباحي',
    emoji: '🛡️',
    defaultPoints: 0,
    isPrivate: true,
  ),
  SuggestedHabit(
    name: 'الامتناع عن العادة السرية',
    emoji: '🛡️',
    defaultPoints: 0,
    isPrivate: true,
  ),
];
