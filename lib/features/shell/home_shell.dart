import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../models/habit.dart';
import '../../services/notification_service.dart';
import '../championships/championships_screen.dart';
import '../chat/chat_screen.dart';
import '../logging/home_screen.dart';
import '../update/version_check.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ReportScreen(),
    StatsScreen(),
    ChampionshipsScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStartup());
  }

  Future<void> _onStartup() async {
    final prefs = ref.read(sharedPrefsProvider);
    if (!(prefs.getBool('permissionAsked') ?? false)) {
      await NotificationService.instance.requestPermissions();
      await prefs.setBool('permissionAsked', true);
    }
    // Wait for the habit list (from cache/server) before syncing reminders and
    // settling qadaa, so both act on real data.
    List<Habit> habits = const [];
    try {
      habits = await ref
          .read(habitsProvider.future)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      habits = ref.read(habitsProvider).valueOrNull ?? const [];
    }
    final tzName = ref.read(appUserProvider).valueOrNull?.timezone;
    await NotificationService.instance.syncAll(habits, tzName);

    // Settle missed prayers for any ended app-day not yet processed.
    try {
      final svc = ref.read(firestoreServiceProvider);
      final loc = ref.read(tzLocationProvider);
      await svc?.settleQadaa(habits: habits, currentAppDay: todayKey(loc));
    } catch (_) {
      // Best-effort — retries next launch.
    }

    // Fallback version gate for full-APK updates (Shorebird handles Dart-only).
    if (mounted) await checkForUpdate(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final hasUnreadChat = ref.watch(hasUnreadChatProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: s.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: s.navReport,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: s.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: s.championships,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasUnreadChat,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: s.chat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
