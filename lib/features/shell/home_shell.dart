import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/settings_controller.dart';
import '../../services/notification_service.dart';
import '../chat/chat_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../logging/home_screen.dart';
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
    LeaderboardScreen(),
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
    // Keep reminders in sync with the user's habits + timezone.
    final tzName = ref.read(appUserProvider).valueOrNull?.timezone;
    final habits = ref.read(habitsProvider).valueOrNull ?? const [];
    await NotificationService.instance.syncAll(habits, tzName);
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
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: s.navLeaderboard,
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
