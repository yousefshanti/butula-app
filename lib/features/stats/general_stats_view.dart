import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/daily_report.dart';
import 'stats_data.dart';
import 'stats_widgets.dart';

class GeneralStatsView extends ConsumerStatefulWidget {
  const GeneralStatsView({super.key});

  @override
  ConsumerState<GeneralStatsView> createState() => _GeneralStatsViewState();
}

class _GeneralStatsViewState extends ConsumerState<GeneralStatsView> {
  StatsRange _range = StatsRange.month;

  Future<Map<String, DailyReport>> _load() async {
    final svc = ref.read(firestoreServiceProvider);
    if (svc == null) return {};
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _range.days));
    final reports = await svc.reportsInRange(dateKey(start), dateKey(end));
    return {for (final r in reports) r.date: r};
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _range.days));

    return FutureBuilder<Map<String, DailyReport>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? {};
        final stats = computeGeneralStats(reports, start, end);

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 8),
            RangeSelector(
                value: _range, onChanged: (r) => setState(() => _range = r), s: s),
            const SizedBox(height: 16),
            if (stats.reportedDays == 0)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(emoji: '📊', title: 'لا توجد بيانات كافية بعد'),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(s.reportScores,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              SeriesChartCard(
                series: stats.scores,
                maxY: 100,
                color: BrandColors.green,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: s.dailyAverage,
                        value: stats.dailyAverage.toStringAsFixed(0),
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: s.bestDay,
                        value: '${stats.bestDay}',
                        icon: Icons.emoji_events,
                        color: BrandColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(s.heatmap,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              _Heatmap(reports: reports),
            ],
          ],
        );
      },
    );
  }
}

/// Current-month calendar heatmap, each day colored by its certified score.
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.reports});
  final Map<String, DailyReport> reports;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = first.weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemCount: leading + daysInMonth,
        itemBuilder: (context, i) {
          if (i < leading) return const SizedBox.shrink();
          final day = i - leading + 1;
          final key = dateKey(DateTime(now.year, now.month, day));
          final r = reports[key];
          final score = r?.totalPoints ?? 0;
          final has = r != null && r.isCertified;
          final color = has
              ? Color.lerp(BrandColors.gold.withValues(alpha: 0.3),
                  BrandColors.green, (score / 100).clamp(0.0, 1.0))!
              : Theme.of(context).colorScheme.surfaceContainerHighest;
          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$day',
                  style: TextStyle(
                      fontSize: 11,
                      color: has && score > 50 ? Colors.white : null)),
            ),
          );
        },
      ),
    );
  }
}
