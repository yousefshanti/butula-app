import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/scoring.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../services/notification_service.dart';
import '../habits/emoji_icon_picker.dart';
import 'conflict_resolution_screen.dart';
import 'report_item.dart';

class ReportFlowScreen extends ConsumerStatefulWidget {
  const ReportFlowScreen({super.key, required this.date, required this.isEdit});
  final String date;
  final bool isEdit;

  @override
  ConsumerState<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends ConsumerState<ReportFlowScreen> {
  late List<Habit> _daily;
  late List<ReportItem> _items;
  final Map<String, bool> _answers = {};
  DailyLog _log = const DailyLog(date: '');
  int _step = 0;
  bool _ready = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _daily = ref.read(dailyHabitsProvider);
    _items = buildReportItems(_daily);
    final svc = ref.read(firestoreServiceProvider);
    _log = (await svc?.getLog(widget.date)) ?? DailyLog.empty(widget.date);

    Map<String, bool> initial;
    if (widget.isEdit) {
      final report = await svc?.getReport(widget.date);
      initial = report?.answers ?? {};
    } else {
      initial = {}; // pre-fill from the log below
    }
    for (final item in _items) {
      _answers[item.key] = initial[item.key] ?? _log.isDone(item.key);
    }
    if (mounted) setState(() => _ready = true);
  }

  int get _total => dailyScore(_daily, _doneKeys);
  Set<String> get _doneKeys =>
      _answers.entries.where((e) => e.value).map((e) => e.key).toSet();

  void _answer(bool value) {
    setState(() {
      _answers[_items[_step].key] = value;
      if (_step < _items.length) _step++;
    });
  }

  Future<void> _certify() async {
    final s = ref.read(stringsProvider);
    // Detect conflicts vs the habit log.
    final conflicts = <Conflict>[];
    for (final item in _items) {
      final reportAns = _answers[item.key] ?? false;
      final logAns = _log.isDone(item.key);
      if (reportAns != logAns) {
        conflicts.add(Conflict(
          item: item,
          reportAnswer: reportAns,
          logAnswer: logAns,
        ));
      }
    }

    Map<String, bool> logUpdates = {};
    if (conflicts.isNotEmpty) {
      final result = await Navigator.of(context).push<ConflictResult>(
        MaterialPageRoute(
          builder: (_) => ConflictResolutionScreen(conflicts: conflicts),
        ),
      );
      if (result == null) return; // cancelled — cannot certify unresolved
      _answers.addAll(result.answers);
      logUpdates = result.logUpdates;
    }

    setState(() => _submitting = true);
    final svc = ref.read(firestoreServiceProvider);
    final user = ref.read(appUserProvider).valueOrNull;
    if (svc == null || user == null) {
      setState(() => _submitting = false);
      return;
    }

    if (logUpdates.isNotEmpty) {
      await svc.mergeLog(widget.date, logUpdates, markEdited: true);
    }
    await svc.certifyReport(
      date: widget.date,
      answers: Map<String, bool>.from(_answers),
      totalPoints: _total,
      userName: user.name,
      isEdit: widget.isEdit,
    );

    // Reconcile qadaa from the certified prayer answers (No -> track missed).
    for (final habit in _daily.where((h) => h.hasSubItems)) {
      for (var i = 0; i < habit.subItems.length; i++) {
        await svc.reconcilePrayerQadaa(
          prayerKey: habit.subItems[i],
          missedDate: widget.date,
          done: _answers[habit.logKeys[i]] ?? false,
        );
      }
    }

    await NotificationService.instance.cancelTonight10pmReminder();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.reportCertified} — $_total/100'),
          backgroundColor: BrandColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(s.noHabitsToday)),
      );
    }

    final isConfirm = _step >= _items.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? s.editReport : s.certifiedReport),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _step / _items.length,
            minHeight: 4,
          ),
        ),
      ),
      body: isConfirm ? _confirmView(s) : _itemView(s),
    );
  }

  Widget _itemView(dynamic s) {
    final item = _items[_step];
    final current = _answers[item.key] ?? false;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text('${_step + 1} / ${_items.length}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          habitIcon(item.emoji, item.iconCodePoint, size: 64),
          const SizedBox(height: 16),
          Text(item.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  label: s.no,
                  icon: Icons.close,
                  color: BrandColors.danger,
                  selected: !current && _answers.containsKey(item.key),
                  onTap: () => _answer(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnswerButton(
                  label: s.yes,
                  icon: Icons.check,
                  color: BrandColors.success,
                  selected: current,
                  onTap: () => _answer(true),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_step > 0)
            TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_forward),
              label: Text(s.back),
            ),
        ],
      ),
    );
  }

  Widget _confirmView(dynamic s) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BrandColors.green, BrandColors.greenLight],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(s.finalTotal,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('$_total/100',
                  style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final ans = _answers[item.key] ?? false;
              return ListTile(
                leading: habitIcon(item.emoji, item.iconCodePoint, size: 24),
                title: Text(item.label),
                trailing: Icon(
                  ans ? Icons.check_circle : Icons.cancel,
                  color: ans ? BrandColors.success : BrandColors.danger,
                ),
                onTap: () => setState(() => _step = i),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _submitting ? null : _certify,
              icon: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified),
              label: Text(s.certifyReport),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 40, color: selected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
