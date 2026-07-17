import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../habits/emoji_icon_picker.dart';
import 'report_item.dart';

class Conflict {
  const Conflict({
    required this.item,
    required this.reportAnswer,
    required this.logAnswer,
  });
  final ReportItem item;
  final bool reportAnswer; // what the report currently says
  final bool logAnswer; // what the habit log says
}

/// Result of resolving conflicts: the final answers, plus which log keys must
/// be updated (the "keep report answer" choices).
class ConflictResult {
  const ConflictResult({required this.answers, required this.logUpdates});
  final Map<String, bool> answers;
  final Map<String, bool> logUpdates;
}

/// Lists every mismatch between the report and the habit log. The report
/// cannot be certified until all conflicts are resolved.
class ConflictResolutionScreen extends ConsumerStatefulWidget {
  const ConflictResolutionScreen({super.key, required this.conflicts});
  final List<Conflict> conflicts;

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen> {
  // true = keep report answer, false = use log answer, null = unresolved.
  final Map<String, bool?> _choice = {};

  @override
  void initState() {
    super.initState();
    for (final c in widget.conflicts) {
      _choice[c.item.key] = null;
    }
  }

  bool get _allResolved => _choice.values.every((v) => v != null);

  void _confirm() {
    final answers = <String, bool>{};
    final logUpdates = <String, bool>{};
    for (final c in widget.conflicts) {
      final keepReport = _choice[c.item.key]!;
      if (keepReport) {
        answers[c.item.key] = c.reportAnswer;
        logUpdates[c.item.key] = c.reportAnswer; // update the log to match
      } else {
        answers[c.item.key] = c.logAnswer; // change the report answer
      }
    }
    Navigator.of(context).pop(
      ConflictResult(answers: answers, logUpdates: logUpdates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.conflictsTitle)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrandColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: BrandColors.danger),
                const SizedBox(width: 10),
                Expanded(child: Text(s.conflictsBody)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.conflicts.length,
              itemBuilder: (context, i) {
                final c = widget.conflicts[i];
                final choice = _choice[c.item.key];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            habitIcon(c.item.emoji, c.item.iconCodePoint,
                                size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.item.label,
                                  style: theme.textTheme.titleMedium),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'التقرير: ${c.reportAnswer ? s.yes : s.no}'
                          '  •  السجل: ${c.logAnswer ? s.yes : s.no}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                                value: true, label: Text(s.keepReportAnswer)),
                            ButtonSegment(
                                value: false, label: Text(s.useLogAnswer)),
                          ],
                          selected: choice == null ? {} : {choice},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (sel) => setState(() =>
                              _choice[c.item.key] =
                                  sel.isEmpty ? null : sel.first),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_allResolved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(s.resolveAllConflicts,
                          style: const TextStyle(color: BrandColors.danger)),
                    ),
                  FilledButton(
                    onPressed: _allResolved ? _confirm : null,
                    child: Text(s.confirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
