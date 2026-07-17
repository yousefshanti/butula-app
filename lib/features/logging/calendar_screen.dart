import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/scoring.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../models/daily_log.dart';
import 'day_log_screen.dart';

const _monthNames = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];
const _weekdayShort = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Future<Map<String, DailyLog>> _loadMonth() async {
    final svc = ref.read(firestoreServiceProvider);
    if (svc == null) return {};
    final first = DateTime(_month.year, _month.month, 1);
    final last = DateTime(_month.year, _month.month + 1, 0);
    final logs = await svc.logsInRange(dateKey(first), dateKey(last));
    return {for (final l in logs) l.date: l};
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final daily = ref.watch(dailyHabitsProvider);
    final theme = Theme.of(context);

    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-based leading blanks (DateTime.weekday: Mon=1..Sun=7).
    final leading = first.weekday - 1;
    final todayK = todayKey(ref.watch(tzLocationProvider));

    return Scaffold(
      appBar: AppBar(title: Text(s.calendar)),
      body: FutureBuilder<Map<String, DailyLog>>(
        future: _loadMonth(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? {};
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _month =
                          DateTime(_month.year, _month.month - 1)),
                    ),
                    Text(
                      '${_monthNames[_month.month - 1]} ${_month.year}',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _month =
                          DateTime(_month.year, _month.month + 1)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _weekdayShort
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant)),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: leading + daysInMonth,
                  itemBuilder: (context, i) {
                    if (i < leading) return const SizedBox.shrink();
                    final day = i - leading + 1;
                    final date = DateTime(_month.year, _month.month, day);
                    final key = dateKey(date);
                    final isFuture = key.compareTo(todayK) > 0;
                    final log = logs[key];
                    final score = log == null
                        ? 0
                        : dailyScore(daily, log.doneKeys);
                    return _DayCell(
                      day: day,
                      score: score,
                      hasLog: log != null,
                      isToday: key == todayK,
                      editedLater: log?.editedLater ?? false,
                      disabled: isFuture,
                      onTap: isFuture
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DayLogScreen(date: key),
                                ),
                              );
                              setState(() {}); // refresh after edits
                            },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.score,
    required this.hasLog,
    required this.isToday,
    required this.editedLater,
    required this.disabled,
    this.onTap,
  });

  final int day;
  final int score;
  final bool hasLog;
  final bool isToday;
  final bool editedLater;
  final bool disabled;
  final VoidCallback? onTap;

  Color _bg(BuildContext context) {
    if (disabled) return Colors.transparent;
    if (!hasLog) return Theme.of(context).colorScheme.surfaceContainerHighest;
    final t = (score / 100).clamp(0.0, 1.0);
    return Color.lerp(
      BrandColors.gold.withValues(alpha: 0.25),
      BrandColors.green,
      t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bg(context);
    final onBg = hasLog && score > 50 ? Colors.white : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: BrandColors.gold, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$day',
                      style: TextStyle(
                          color: disabled
                              ? Theme.of(context).disabledColor
                              : onBg,
                          fontWeight: FontWeight.bold)),
                  if (hasLog)
                    Text('$score',
                        style: TextStyle(fontSize: 10, color: onBg)),
                ],
              ),
            ),
            if (editedLater)
              const Positioned(
                top: 3,
                right: 3,
                child: Icon(Icons.edit, size: 10, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}
