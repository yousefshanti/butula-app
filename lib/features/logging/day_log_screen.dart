import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/scoring.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import 'habit_check_tile.dart';

/// Edit a past day's log. Changes are flagged as "edited later".
class DayLogScreen extends ConsumerWidget {
  const DayLogScreen({super.key, required this.date});
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
    final log = ref.watch(logProvider(date)).valueOrNull ?? DailyLog.empty(date);
    final daily = habits.where((h) => h.isDaily).toList();
    final weekly = habits.where((h) => h.type == HabitType.weekly).toList();
    final monthly = habits.where((h) => h.type == HabitType.monthly).toList();
    final score = dailyScore(daily, log.doneKeys);

    return Scaffold(
      appBar: AppBar(
        title: Text(date),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('$score/100',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: BrandColors.green, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (log.editedLater)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16),
                  const SizedBox(width: 8),
                  Text(s.editedLater),
                ],
              ),
            ),
          ...daily.map((h) => _tile(h, log)),
          if (weekly.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...weekly.map((h) => _tile(h, log)),
          ],
          if (monthly.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...monthly.map((h) => _tile(h, log)),
          ],
        ],
      ),
    );
  }

  Widget _tile(Habit h, DailyLog log) {
    if (h.hasSubItems) {
      return PrayerCheckCard(habit: h, date: date, log: log, isPast: true);
    }
    return HabitCheckTile(habit: h, date: date, log: log, isPast: true);
  }
}
