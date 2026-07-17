import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/leaderboard_entry.dart';

enum _Filter { month, allTime }

final _filterProvider = StateProvider<_Filter>((_) => _Filter.allTime);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final filter = ref.watch(_filterProvider);
    final entriesAsync = ref.watch(leaderboardProvider);
    final uid = ref.watch(currentUidProvider);
    final loc = ref.watch(tzLocationProvider);
    final currentMonth = monthKeyOf(tz.TZDateTime.now(loc));

    return Scaffold(
      appBar: AppBar(title: Text(s.leaderboard)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_Filter>(
              segments: [
                ButtonSegment(value: _Filter.allTime, label: Text(s.allTime)),
                ButtonSegment(value: _Filter.month, label: Text(s.thisMonth)),
              ],
              selected: {filter},
              showSelectedIcon: false,
              onSelectionChanged: (sel) =>
                  ref.read(_filterProvider.notifier).state = sel.first,
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${s.error}\n$e')),
              data: (entries) {
                final ranked = _rank(entries, filter, currentMonth);
                if (ranked.isEmpty) {
                  return EmptyState(emoji: '🏆', title: s.noParticipants);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: ranked.length,
                  itemBuilder: (context, i) {
                    final e = ranked[i];
                    final points = filter == _Filter.allTime
                        ? e.totalPoints
                        : (e.monthKey == currentMonth ? e.monthPoints : 0);
                    return _LeaderRow(
                      rank: i + 1,
                      entry: e,
                      points: points,
                      isCurrentUser: e.uid == uid,
                      s: s,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<LeaderboardEntry> _rank(
    List<LeaderboardEntry> entries,
    _Filter filter,
    String currentMonth,
  ) {
    int score(LeaderboardEntry e) => filter == _Filter.allTime
        ? e.totalPoints
        : (e.monthKey == currentMonth ? e.monthPoints : 0);
    return List<LeaderboardEntry>.from(entries)
      ..sort((a, b) => score(b).compareTo(score(a)));
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.entry,
    required this.points,
    required this.isCurrentUser,
    required this.s,
  });
  final int rank;
  final LeaderboardEntry entry;
  final int points;
  final bool isCurrentUser;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isCurrentUser ? BrandColors.gold.withValues(alpha: 0.18) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isCurrentUser
            ? const BorderSide(color: BrandColors.gold, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: medal != null
                  ? Text(medal, style: const TextStyle(fontSize: 24))
                  : Text('$rank',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name.isEmpty ? '—' : entry.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: BrandColors.gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(s.you,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.lastReport}: ${entry.lastReportPoints}  •  '
                    '${s.streak}: ${entry.streak} 🔥',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$points',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: BrandColors.green, fontWeight: FontWeight.bold)),
                Text(s.totalPointsLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
