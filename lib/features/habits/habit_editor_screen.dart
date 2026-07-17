import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../models/habit.dart';
import 'emoji_icon_picker.dart';
import 'habit_controller.dart';

const _weekdayLabels = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

class HabitEditorScreen extends ConsumerStatefulWidget {
  const HabitEditorScreen({super.key, this.habit});
  final Habit? habit;

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends ConsumerState<HabitEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _points;
  late String _emoji;
  int? _iconCodePoint;
  late HabitType _type;
  late HabitSchedule _schedule;
  late bool _isPrivate;
  late bool _reminderEnabled;
  TimeOfDay? _reminderTime;
  bool _weeklyByCount = false;
  bool _monthlyByCount = false;
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _points = TextEditingController(text: (h?.points ?? 10).toString());
    _emoji = h?.emoji ?? '⭐';
    _iconCodePoint = h?.iconCodePoint;
    _type = h?.type ?? HabitType.daily;
    _schedule = h?.schedule ?? const HabitSchedule();
    _isPrivate = h?.isPrivate ?? false;
    _reminderEnabled = h?.reminderEnabled ?? false;
    _reminderTime = h?.reminderTime;
    _weeklyByCount = _schedule.timesPerWeek != null && _schedule.weekdays.isEmpty;
    _monthlyByCount = _schedule.timesPerMonth != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final choice = await showIconPicker(context);
    if (choice == null) return;
    setState(() {
      if (choice.emoji != null) {
        _emoji = choice.emoji!;
        _iconCodePoint = null;
      } else {
        _iconCodePoint = choice.iconCodePoint;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final points = _isPrivate ? 0 : (int.tryParse(_points.text.trim()) ?? 0);

    var schedule = const HabitSchedule();
    if (_type == HabitType.weekly) {
      schedule = _weeklyByCount
          ? HabitSchedule(timesPerWeek: _schedule.timesPerWeek ?? 3)
          : HabitSchedule(
              weekdays: _schedule.weekdays.isEmpty ? [1] : _schedule.weekdays);
    } else if (_type == HabitType.monthly) {
      schedule = _monthlyByCount
          ? HabitSchedule(timesPerMonth: _schedule.timesPerMonth ?? 1)
          : HabitSchedule(dayOfMonth: _schedule.dayOfMonth ?? 1);
    }

    final reminderMinutes = _reminderEnabled && _reminderTime != null
        ? _reminderTime!.hour * 60 + _reminderTime!.minute
        : null;

    setState(() => _saving = true);
    final controller = ref.read(habitControllerProvider);
    final base = widget.habit ?? Habit(id: '', name: '');
    final habit = base.copyWith(
      name: _name.text.trim(),
      emoji: _emoji,
      iconCodePoint: _iconCodePoint,
      clearIcon: _iconCodePoint == null,
      points: points,
      type: _type,
      schedule: schedule,
      isPrivate: _isPrivate,
      reminderEnabled: _reminderEnabled && reminderMinutes != null,
      reminderMinutes: reminderMinutes,
      clearReminder: reminderMinutes == null,
    );

    if (_isEditing) {
      await controller.update(habit);
    } else {
      await controller.add(habit);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final s = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.delete),
        content: Text('${s.delete} "${widget.habit!.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(habitControllerProvider).delete(widget.habit!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editHabit : s.newHabit),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: BrandColors.danger),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _pickIcon,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: BrandColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: habitIcon(_emoji, _iconCodePoint, size: 44),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
                child: TextButton.icon(
              onPressed: _pickIcon,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(s.icon),
            )),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: s.habitName,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.emptyName : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
              title: Text(s.privateItem),
              subtitle: Text(s.privateHint, style: theme.textTheme.bodySmall),
              secondary: const Icon(Icons.shield_outlined),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_isPrivate) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _points,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: s.points,
                  prefixIcon: const Icon(Icons.stars_outlined),
                  helperText: _type == HabitType.daily
                      ? s.pointsMustBe100
                      : s.weeklyMonthlyNote,
                  helperMaxLines: 3,
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 0) return s.requiredField;
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            Text(s.type, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<HabitType>(
              segments: [
                ButtonSegment(value: HabitType.daily, label: Text(s.daily)),
                ButtonSegment(value: HabitType.weekly, label: Text(s.weekly)),
                ButtonSegment(value: HabitType.monthly, label: Text(s.monthly)),
              ],
              selected: {_type},
              onSelectionChanged: (sel) => setState(() => _type = sel.first),
            ),
            if (_type == HabitType.weekly) _weeklyOptions(s, theme),
            if (_type == HabitType.monthly) _monthlyOptions(s, theme),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
              title: Text(s.enableReminder),
              secondary: const Icon(Icons.alarm),
              contentPadding: EdgeInsets.zero,
            ),
            if (_reminderEnabled)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(s.reminderTime),
                trailing: Text(
                  _reminderTime?.format(context) ?? '—',
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
                  );
                  if (t != null) setState(() => _reminderTime = t);
                },
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.save),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _weeklyOptions(dynamic s, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(s.chooseWeekdays)),
            ButtonSegment(value: true, label: Text(s.timesPerWeek)),
          ],
          selected: {_weeklyByCount},
          onSelectionChanged: (sel) =>
              setState(() => _weeklyByCount = sel.first),
        ),
        const SizedBox(height: 12),
        if (!_weeklyByCount)
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _schedule.weekdays.contains(day);
              return FilterChip(
                label: Text(_weekdayLabels[i]),
                selected: selected,
                onSelected: (v) => setState(() {
                  final days = List<int>.from(_schedule.weekdays);
                  if (v) {
                    days.add(day);
                  } else {
                    days.remove(day);
                  }
                  _schedule = _schedule.copyWith(weekdays: days);
                }),
              );
            }),
          )
        else
          _countStepper(
            value: _schedule.timesPerWeek ?? 3,
            min: 1,
            max: 7,
            label: s.timesPerWeek,
            onChanged: (v) =>
                setState(() => _schedule = _schedule.copyWith(timesPerWeek: v)),
          ),
      ],
    );
  }

  Widget _monthlyOptions(dynamic s, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(s.dayOfMonth)),
            ButtonSegment(value: true, label: Text(s.timesPerMonth)),
          ],
          selected: {_monthlyByCount},
          onSelectionChanged: (sel) =>
              setState(() => _monthlyByCount = sel.first),
        ),
        const SizedBox(height: 12),
        if (!_monthlyByCount)
          _countStepper(
            value: _schedule.dayOfMonth ?? 1,
            min: 1,
            max: 28,
            label: s.dayOfMonth,
            onChanged: (v) =>
                setState(() => _schedule = _schedule.copyWith(dayOfMonth: v)),
          )
        else
          _countStepper(
            value: _schedule.timesPerMonth ?? 1,
            min: 1,
            max: 30,
            label: s.timesPerMonth,
            onChanged: (v) =>
                setState(() => _schedule = _schedule.copyWith(timesPerMonth: v)),
          ),
      ],
    );
  }

  Widget _countStepper({
    required int value,
    required int min,
    required int max,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
