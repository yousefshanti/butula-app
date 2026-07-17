import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../models/habit.dart';
import '../../services/notification_service.dart';

/// Proportionally adjusts the point weights of the given daily habits so they
/// sum to exactly 100. Private habits are ignored (they carry no points).
/// Uses largest-remainder rounding; every habit keeps at least 1 point.
List<Habit> autoDistributeTo100(List<Habit> dailyHabits) {
  final scored = dailyHabits.where((h) => !h.isPrivate).toList();
  if (scored.isEmpty) return dailyHabits;

  final currentTotal = scored.fold<int>(0, (a, h) => a + h.points);
  final n = scored.length;

  // Raw proportional (or equal split if everything is currently zero).
  final raw = <double>[];
  for (final h in scored) {
    raw.add(currentTotal == 0 ? 100 / n : h.points * 100 / currentTotal);
  }

  // Floor, keep a floor of 1, then hand out the remainder by largest fraction.
  final floors = raw.map((v) => v.floor().clamp(1, 100)).toList();
  var assigned = floors.fold<int>(0, (a, b) => a + b);
  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));

  var i = 0;
  while (assigned < 100) {
    floors[order[i % n]]++;
    assigned++;
    i++;
  }
  while (assigned > 100) {
    final idx = order[i % n];
    if (floors[idx] > 1) {
      floors[idx]--;
      assigned--;
    }
    i++;
    if (i > n * 200) break; // safety
  }

  final byId = {for (var k = 0; k < n; k++) scored[k].id: floors[k]};
  return dailyHabits
      .map((h) => byId.containsKey(h.id)
          ? h.copyWith(points: byId[h.id])
          : h)
      .toList();
}

/// Write-side actions for habits (also keeps reminders in sync).
class HabitController {
  HabitController(this._ref);
  final Ref _ref;

  String? get _tz => _ref.read(appUserProvider).valueOrNull?.timezone;

  Future<Habit?> add(Habit habit) async {
    final svc = _ref.read(firestoreServiceProvider);
    if (svc == null) return null;
    final order = _ref.read(habitsProvider).valueOrNull?.length ?? 0;
    final created = await svc.addHabit(habit.copyWith(order: order));
    await NotificationService.instance.scheduleHabitReminder(created, _tz);
    return created;
  }

  Future<void> addMany(List<Habit> habits) async {
    final svc = _ref.read(firestoreServiceProvider);
    if (svc == null) return;
    final base = _ref.read(habitsProvider).valueOrNull?.length ?? 0;
    final ordered = <Habit>[];
    for (var i = 0; i < habits.length; i++) {
      ordered.add(habits[i].copyWith(order: base + i));
    }
    await svc.addHabits(ordered);
  }

  Future<void> update(Habit habit) async {
    final svc = _ref.read(firestoreServiceProvider);
    if (svc == null) return;
    await svc.updateHabit(habit);
    await NotificationService.instance.scheduleHabitReminder(habit, _tz);
  }

  Future<void> delete(String habitId) async {
    final svc = _ref.read(firestoreServiceProvider);
    if (svc == null) return;
    await svc.deleteHabit(habitId);
    await NotificationService.instance.cancelHabitReminder(habitId);
  }

  Future<void> reorder(List<Habit> ordered) async {
    final svc = _ref.read(firestoreServiceProvider);
    await svc?.reorderHabits(ordered);
  }

  Future<void> applyAutoDistribute() async {
    final svc = _ref.read(firestoreServiceProvider);
    if (svc == null) return;
    final daily = _ref.read(dailyHabitsProvider);
    final updated = autoDistributeTo100(daily);
    for (final h in updated) {
      await svc.updateHabit(h);
    }
  }
}

final habitControllerProvider =
    Provider<HabitController>((ref) => HabitController(ref));
