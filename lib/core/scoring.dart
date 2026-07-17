import '../models/habit.dart';

/// Daily score (out of 100) from the daily habits and the completed log keys.
/// Private habits contribute 0 (handled in [Habit.scoreFor]).
int dailyScore(List<Habit> dailyHabits, Set<String> doneKeys) =>
    dailyHabits.fold<int>(0, (acc, h) => acc + h.scoreFor(doneKeys));
