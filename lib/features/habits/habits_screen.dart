import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/habit.dart';
import 'emoji_icon_picker.dart';
import 'habit_controller.dart';
import 'habit_editor_screen.dart';
import 'suggested_habits_sheet.dart';

/// The habit builder: create/edit/delete/reorder habits + the 100-point rule.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final total = ref.watch(dailyPointsTotalProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.myHabits)),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.error}\n$e')),
        data: (habits) {
          if (habits.isEmpty) return _Onboarding(s: s);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: PointsTotalBar(total: total, label: s.myHabits),
              ),
              if (total != 100)
                PointsWarningBanner(
                  total: total,
                  onAutoDistribute: () =>
                      ref.read(habitControllerProvider).applyAutoDistribute(),
                ),
              Expanded(child: _HabitList(habits: habits)),
            ],
          );
        },
      ),
      floatingActionButton: habitsAsync.valueOrNull?.isEmpty ?? true
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: Text(s.addHabit),
              backgroundColor: BrandColors.green,
              foregroundColor: Colors.white,
            ),
    );
  }

  static void _openEditor(BuildContext context, {Habit? habit}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HabitEditorScreen(habit: habit),
    ));
  }
}

class _Onboarding extends ConsumerWidget {
  const _Onboarding({required this.s});
  final dynamic s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      emoji: '🌱',
      title: s.emptyHabitsTitle,
      body: s.emptyHabitsBody,
      action: Column(
        children: [
          FilledButton.icon(
            onPressed: () async {
              final chosen = await showSuggestedHabitsSheet(context, s);
              if (chosen != null && chosen.isNotEmpty) {
                await ref.read(habitControllerProvider).addMany(chosen);
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: Text(s.startFromSuggested),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const HabitEditorScreen(),
            )),
            icon: const Icon(Icons.add),
            label: Text(s.startFromScratch),
          ),
        ],
      ),
    );
  }
}

class _HabitList extends ConsumerWidget {
  const _HabitList({required this.habits});
  final List<Habit> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: habits.length,
      onReorderItem: (oldIndex, newIndex) {
        final list = List<Habit>.from(habits);
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);
        ref.read(habitControllerProvider).reorder(list);
      },
      itemBuilder: (context, i) {
        final h = habits[i];
        return Card(
          key: ValueKey(h.id),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: SizedBox(
              width: 40,
              child: Center(child: habitIcon(h.emoji, h.iconCodePoint, size: 28)),
            ),
            title: Text(h.name),
            subtitle: Text(_subtitle(h, s)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!h.isPrivate)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${h.points}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HabitEditorScreen(habit: h),
            )),
          ),
        );
      },
    );
  }

  String _subtitle(Habit h, dynamic s) {
    if (h.isPrivate) return s.privateItem;
    final parts = <String>[];
    switch (h.type) {
      case HabitType.daily:
        parts.add(s.daily);
        break;
      case HabitType.weekly:
        parts.add(s.weekly);
        break;
      case HabitType.monthly:
        parts.add(s.monthly);
        break;
    }
    if (h.hasSubItems) parts.add('${h.subItems.length} صلوات');
    if (h.reminderEnabled) parts.add('⏰');
    return parts.join(' • ');
  }
}
