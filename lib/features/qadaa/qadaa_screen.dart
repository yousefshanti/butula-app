import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/suggested_habits.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/qadaa_entry.dart';

class QadaaScreen extends ConsumerWidget {
  const QadaaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final entriesAsync = ref.watch(qadaaProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.qadaaList),
          bottom: TabBar(
            tabs: [
              Tab(text: s.pending),
              Tab(text: s.qadaaHistory),
            ],
          ),
        ),
        body: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${s.error}\n$e')),
          data: (entries) {
            final pending = entries.where((q) => q.isPending).toList();
            final history = entries.where((q) => !q.isPending).toList()
              ..sort((a, b) =>
                  (b.madeUpDate ?? '').compareTo(a.madeUpDate ?? ''));
            return TabBarView(
              children: [
                _PendingView(pending: pending, s: s),
                _HistoryView(history: history, s: s),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingView extends ConsumerWidget {
  const _PendingView({required this.pending, required this.s});
  final List<QadaaEntry> pending;
  final dynamic s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pending.isEmpty) {
      return EmptyState(emoji: '🕌', title: s.noPendingQadaa, body: s.qadaaNote);
    }
    // Group by prayer name, ordered by the canonical prayer order.
    final byPrayer = <String, List<QadaaEntry>>{};
    for (final e in pending) {
      byPrayer.putIfAbsent(e.prayerKey, () => []).add(e);
    }
    final orderedKeys = [
      ...prayerNames.where(byPrayer.containsKey),
      ...byPrayer.keys.where((k) => !prayerNames.contains(k)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(s.qadaaNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        for (final prayer in orderedKeys)
          _PrayerGroup(
            prayer: prayer,
            entries: (byPrayer[prayer]!
              ..sort((a, b) => b.missedDate.compareTo(a.missedDate))),
            s: s,
          ),
      ],
    );
  }
}

class _PrayerGroup extends ConsumerWidget {
  const _PrayerGroup({
    required this.prayer,
    required this.entries,
    required this.s,
  });
  final String prayer;
  final List<QadaaEntry> entries;
  final dynamic s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = ref.watch(tzLocationProvider);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🕌', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(prayer,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: BrandColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(s.times(entries.length),
                      style: const TextStyle(
                          color: BrandColors.danger,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 16),
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.event_busy, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.missedOn(e.missedDate))),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(firestoreServiceProvider)
                            ?.markQadaaMadeUp(e.id, todayKey(loc)),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(s.markMadeUp),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _HistoryView extends ConsumerWidget {
  const _HistoryView({required this.history, required this.s});
  final List<QadaaEntry> history;
  final dynamic s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return EmptyState(emoji: '📜', title: s.noQadaaHistory);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final e = history[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: BrandColors.success,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(e.prayerKey),
            subtitle: Text('${s.missedOn(e.missedDate)}\n${s.madeUpOn(e.madeUpDate ?? '')}'),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () =>
                  ref.read(firestoreServiceProvider)?.undoQadaaMadeUp(e.id),
              child: Text(s.undo),
            ),
          ),
        );
      },
    );
  }
}
