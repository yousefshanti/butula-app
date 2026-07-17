import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/suggested_habits.dart';
import '../../core/theme.dart';
import '../../models/habit.dart';

/// Bottom sheet to pick suggested habits (and private items). Returns the
/// chosen [Habit]s (without ids/order — the controller assigns those).
Future<List<Habit>?> showSuggestedHabitsSheet(
  BuildContext context,
  AppStrings s,
) {
  return showModalBottomSheet<List<Habit>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _SuggestedSheet(s: s),
  );
}

class _SuggestedSheet extends StatefulWidget {
  const _SuggestedSheet({required this.s});
  final AppStrings s;

  @override
  State<_SuggestedSheet> createState() => _SuggestedSheetState();
}

class _SuggestedSheetState extends State<_SuggestedSheet> {
  final _selected = <SuggestedHabit>{};

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(s.suggestedHabits,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_selected.length}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: BrandColors.green)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ...suggestedHabits.map(_tile),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(s.privateItem,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
                ...suggestedPrivateItems.map(_tile),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        final habits = _selected
                            .map((sh) => sh.toHabit('', 0))
                            .toList();
                        Navigator.of(context).pop(habits);
                      },
                child: Text('${s.addSelected} (${_selected.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(SuggestedHabit sh) {
    final checked = _selected.contains(sh);
    return CheckboxListTile(
      value: checked,
      onChanged: (v) => setState(() {
        if (v == true) {
          _selected.add(sh);
        } else {
          _selected.remove(sh);
        }
      }),
      secondary: Text(sh.emoji, style: const TextStyle(fontSize: 26)),
      title: Text(sh.name),
      subtitle: sh.isPrivate
          ? Text(widget.s.privateItem)
          : Text('${widget.s.points}: ${sh.defaultPoints}'
              '${sh.subItems.isNotEmpty ? ' • ${sh.subItems.length} صلوات' : ''}'),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
