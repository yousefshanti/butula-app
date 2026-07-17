import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/daily_log.dart';
import '../habits/emoji_icon_picker.dart';
import 'stats_data.dart';
import 'stats_widgets.dart';

class HabitStatsView extends ConsumerStatefulWidget {
  const HabitStatsView({super.key});

  @override
  ConsumerState<HabitStatsView> createState() => _HabitStatsViewState();
}

class _HabitStatsViewState extends ConsumerState<HabitStatsView> {
  StatsRange _range = StatsRange.month;
  String? _habitId;

  Future<Map<String, DailyLog>> _load() async {
    final svc = ref.read(firestoreServiceProvider);
    if (svc == null) return {};
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _range.days));
    final logs = await svc.logsInRange(dateKey(start), dateKey(end));
    return {for (final l in logs) l.date: l};
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final habits = ref.watch(habitsProvider).valueOrNull ?? const [];

    if (habits.isEmpty) {
      return EmptyState(emoji: '📈', title: s.noData);
    }

    _habitId ??= habits.first.id;
    final habit = habits.firstWhere((h) => h.id == _habitId,
        orElse: () => habits.first);
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _range.days));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            initialValue: habit.id,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.checklist),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            items: habits
                .map((h) => DropdownMenuItem(
                      value: h.id,
                      child: Row(
                        children: [
                          habitIcon(h.emoji, h.iconCodePoint, size: 20),
                          const SizedBox(width: 8),
                          Flexible(child: Text(h.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _habitId = v),
          ),
        ),
        const SizedBox(height: 12),
        RangeSelector(
            value: _range, onChanged: (r) => setState(() => _range = r), s: s),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, DailyLog>>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final logs = snapshot.data ?? {};
            final stats = computeHabitStats(habit, logs, start, end);
            return Column(
              children: [
                SeriesChartCard(
                  series: stats.series,
                  maxY: 1,
                  color: BrandColors.green,
                  asBars: true,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: s.completionRate,
                          value: '${stats.completionPct.toStringAsFixed(0)}%',
                          icon: Icons.percent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          label: s.currentStreak,
                          value: '${stats.currentStreak}',
                          icon: Icons.local_fire_department,
                          color: BrandColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          label: s.longestStreak,
                          value: '${stats.longestStreak}',
                          icon: Icons.military_tech,
                          color: BrandColors.greenLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
