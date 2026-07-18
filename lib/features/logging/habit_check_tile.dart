import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/theme.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../habits/emoji_icon_picker.dart';
import '../qadaa/qadaa_screen.dart';

/// A single habit's yes/no toggle for a given day, with a point-flash animation.
/// Binary model: default is NO (unchecked); tapping toggles YES/NO.
class HabitCheckTile extends ConsumerStatefulWidget {
  const HabitCheckTile({
    super.key,
    required this.habit,
    required this.date,
    required this.log,
    this.isPast = false,
  });

  final Habit habit;
  final String date;
  final DailyLog log;
  final bool isPast;

  @override
  ConsumerState<HabitCheckTile> createState() => _HabitCheckTileState();
}

class _HabitCheckTileState extends ConsumerState<HabitCheckTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool value) async {
    final svc = ref.read(firestoreServiceProvider);
    if (svc == null) return;
    if (value && !widget.habit.isPrivate && widget.habit.points > 0) {
      _flash.forward(from: 0);
    }
    await svc.setLogValue(
      widget.date,
      widget.habit.id,
      value,
      markEdited: widget.isPast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final done = widget.log.isDone(h.id);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _toggle(!done),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              habitIcon(h.emoji, h.iconCodePoint, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: theme.textTheme.titleMedium),
                    if (!h.isPrivate)
                      Text('${h.points} $_pointsWord',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _PointFlash(controller: _flash, points: h.points),
              const SizedBox(width: 6),
              _CheckButton(done: done, onTap: () => _toggle(!done)),
            ],
          ),
        ),
      ),
    );
  }

  String get _pointsWord => widget.habit.isDaily ? 'نقطة' : 'نقطة (منفصلة)';
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: done ? BrandColors.success : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: done ? BrandColors.success : Colors.grey,
            width: 2,
          ),
        ),
        child: Icon(
          done ? Icons.check : Icons.close,
          size: 20,
          color: done ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}

/// Rising "+N" that fades out — the point-flash on checking a habit.
class _PointFlash extends StatelessWidget {
  const _PointFlash({required this.controller, required this.points});
  final AnimationController controller;
  final int points;

  @override
  Widget build(BuildContext context) {
    if (points <= 0) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        if (v == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: (1 - v).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -20 * v),
            child: Transform.scale(
              scale: 0.8 + 0.6 * v,
              child: Text(
                '+$points',
                style: const TextStyle(
                  color: BrandColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The five prayers, shown as a card with 5 binary sub-item toggles.
class PrayerCheckCard extends ConsumerWidget {
  const PrayerCheckCard({
    super.key,
    required this.habit,
    required this.date,
    required this.log,
    this.isPast = false,
  });

  final Habit habit;
  final String date;
  final DailyLog log;
  final bool isPast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final keys = habit.logKeys;
    final doneCount = keys.where(log.doneKeys.contains).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                habitIcon(habit.emoji, habit.iconCodePoint, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(habit.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.mosque_outlined),
                  tooltip: 'قضاء الصلاة',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QadaaScreen()),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$doneCount/${keys.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 16),
            ...List.generate(keys.length, (i) {
              final key = keys[i];
              final prayerName = habit.subItems[i];
              final done = log.isDone(key);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                value: done,
                title: Text(prayerName),
                onChanged: (v) {
                  final value = v ?? false;
                  final svc = ref.read(firestoreServiceProvider);
                  if (svc == null) return;
                  svc.setLogValue(date, key, value, markEdited: isPast);
                  // Flipping a prayer to YES clears any pending qadaa entry.
                  // Missed prayers are added at the 3AM day-end settlement.
                  if (value) {
                    svc.removePendingMissedPrayer(prayerName, date);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
