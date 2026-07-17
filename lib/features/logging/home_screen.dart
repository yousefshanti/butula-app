import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/scoring.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../habits/habit_controller.dart';
import '../habits/habits_screen.dart';
import 'calendar_screen.dart';
import 'habit_check_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final loc = ref.watch(tzLocationProvider);
    final today = todayKey(loc);
    final habitsAsync = ref.watch(habitsProvider);
    final logAsync = ref.watch(logProvider(today));
    final dailyTotal = ref.watch(dailyPointsTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.today),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: s.calendar,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: s.myHabits,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.error}\n$e')),
        data: (habits) {
          if (habits.isEmpty) return _EmptyHome(s: s);
          final log = logAsync.valueOrNull ?? DailyLog.empty(today);
          final daily = habits.where((h) => h.isDaily).toList();
          final weekly = habits.where((h) => h.type == HabitType.weekly).toList();
          final monthly =
              habits.where((h) => h.type == HabitType.monthly).toList();
          final score = dailyScore(daily, log.doneKeys);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _ScoreHeader(score: score),
              if (dailyTotal != 100)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PointsWarningBanner(
                    total: dailyTotal,
                    onAutoDistribute: () => ref
                        .read(habitControllerProvider)
                        .applyAutoDistribute(),
                  ),
                ),
              const SizedBox(height: 8),
              ...daily.map((h) => _tileFor(h, today, log)),
              if (weekly.isNotEmpty) ...[
                _sectionHeader(context, s.weekly),
                ...weekly.map((h) => _tileFor(h, today, log)),
              ],
              if (monthly.isNotEmpty) ...[
                _sectionHeader(context, s.monthly),
                ...monthly.map((h) => _tileFor(h, today, log)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tileFor(Habit h, String date, DailyLog log) {
    if (h.hasSubItems) {
      return PrayerCheckCard(habit: h, date: date, log: log);
    }
    return HabitCheckTile(habit: h, date: date, log: log);
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: BrandColors.green, fontWeight: FontWeight.bold)),
      );
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (score / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColors.green, BrandColors.greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(BrandColors.gold),
                    ),
                  ),
                ),
                Text('$score',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نتيجة اليوم',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('$score/100',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Text('🏆', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }
}

class _EmptyHome extends ConsumerWidget {
  const _EmptyHome({required this.s});
  final dynamic s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      emoji: '🌱',
      title: s.emptyHabitsTitle,
      body: s.emptyHabitsBody,
      action: FilledButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HabitsScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(s.addHabit),
      ),
    );
  }
}
