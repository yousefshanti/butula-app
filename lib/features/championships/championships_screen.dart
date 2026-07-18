import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../models/championship_entry.dart';
import '../commitment/commitment_screen.dart';

class ChampionshipsScreen extends ConsumerWidget {
  const ChampionshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final loc = ref.watch(tzLocationProvider);
    final currentMonth = currentAppMonthKey(loc);
    final parts = currentMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final entriesAsync = ref.watch(championshipEntriesProvider(currentMonth));
    final monthsAsync = ref.watch(championshipMonthsProvider);
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.championships)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          // Commitment document entry point.
          const _CommitmentCard(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              s.championshipTitle(month, year),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: BrandColors.green, fontWeight: FontWeight.bold),
            ),
          ),
          entriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${s.error}\n$e'),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(s.noStandings)),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _EntryRow(
                      rank: i + 1,
                      entry: entries[i],
                      isCurrentUser: entries[i].uid == uid,
                      s: s,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(s.pastChampionships,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          monthsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (months) {
              final past = months.where((m) => m != currentMonth).toList();
              if (past.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('—',
                      style: Theme.of(context).textTheme.bodyMedium),
                );
              }
              return Column(
                children: past.map((m) => _PastMonthTile(month: m, s: s)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PastMonthTile extends ConsumerWidget {
  const _PastMonthTile({required this.month, required this.s});
  final String month;
  final dynamic s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(s.championshipTitle(m, year)),
        subtitle: Text(s.top10),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          Consumer(
            builder: (context, ref, _) {
              final entriesAsync =
                  ref.watch(championshipEntriesProvider(month));
              return entriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const SizedBox.shrink(),
                data: (entries) {
                  final top = entries.take(10).toList();
                  final uid = ref.watch(currentUidProvider);
                  return Column(
                    children: [
                      for (var i = 0; i < top.length; i++)
                        _EntryRow(
                          rank: i + 1,
                          entry: top[i],
                          isCurrentUser: top[i].uid == uid,
                          s: s,
                          dense: true,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
    required this.s,
    this.dense = false,
  });
  final int rank;
  final ChampionshipEntry entry;
  final bool isCurrentUser;
  final dynamic s;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return Container(
      margin: EdgeInsets.symmetric(horizontal: dense ? 8 : 0, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? BrandColors.gold.withValues(alpha: 0.18) : null,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: BrandColors.gold, width: 1.2)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 20))
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.name.isEmpty ? '—' : entry.name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text('🔥 ${entry.streak}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Text('${entry.points}',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: BrandColors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Entry point to the private commitment document.
class _CommitmentCard extends ConsumerWidget {
  const _CommitmentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Card(
      color: BrandColors.green,
      child: ListTile(
        leading: const Text('📜', style: TextStyle(fontSize: 28)),
        title: Text(
          s.commitmentDoc,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          s.commitmentCardSubtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_left, color: BrandColors.gold),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommitmentScreen()),
        ),
      ),
    );
  }
}
