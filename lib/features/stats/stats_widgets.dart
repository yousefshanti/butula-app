import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'stats_data.dart';

class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.s,
  });
  final StatsRange value;
  final ValueChanged<StatsRange> onChanged;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SegmentedButton<StatsRange>(
        segments: [
          ButtonSegment(value: StatsRange.week, label: Text(s.lastWeek)),
          ButtonSegment(value: StatsRange.month, label: Text(s.lastMonth)),
          ButtonSegment(value: StatsRange.threeMonths, label: Text(s.last3Months)),
          ButtonSegment(value: StatsRange.all, label: Text(s.allTime)),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (sel) => onChanged(sel.first),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = BrandColors.green,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Line/area chart for a 0..maxY series over days.
class SeriesChartCard extends StatelessWidget {
  const SeriesChartCard({
    super.key,
    required this.series,
    required this.maxY,
    required this.color,
    this.asBars = false,
  });
  final List<DaySeriesPoint> series;
  final double maxY;
  final Color color;
  final bool asBars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (series.isEmpty) {
      return const SizedBox(height: 220);
    }
    final n = series.length;
    final labelEvery = (n / 4).ceil().clamp(1, n);

    Widget bottomTitle(double value, TitleMeta meta) {
      final i = value.toInt();
      if (i < 0 || i >= n) return const SizedBox.shrink();
      if (i % labelEvery != 0 && i != n - 1) return const SizedBox.shrink();
      final d = series[i].date;
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('${d.day}/${d.month}',
            style: theme.textTheme.bodySmall),
      );
    }

    final titlesData = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          interval: maxY / 2,
          getTitlesWidget: (v, _) =>
              Text(v.toInt().toString(), style: theme.textTheme.bodySmall),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: bottomTitle,
        ),
      ),
    );

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: asBars
            ? BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  titlesData: titlesData,
                  gridData: FlGridData(show: true, horizontalInterval: maxY / 2),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < n; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: series[i].value,
                          color: color,
                          width: (200 / n).clamp(2, 14),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ]),
                  ],
                ),
              )
            : LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  titlesData: titlesData,
                  gridData: FlGridData(show: true, horizontalInterval: maxY / 2),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < n; i++)
                          FlSpot(i.toDouble(), series[i].value),
                      ],
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
