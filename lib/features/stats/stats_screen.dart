import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings_controller.dart';
import 'general_stats_view.dart';
import 'habit_stats_view.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.statistics),
          bottom: TabBar(
            tabs: [
              Tab(text: s.general),
              Tab(text: s.perHabit),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralStatsView(),
            HabitStatsView(),
          ],
        ),
      ),
    );
  }
}
