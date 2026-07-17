import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../services/notification_service.dart';
import '../auth/timezone_setup_screen.dart';
import '../habits/habits_screen.dart';
import '../qadaa/qadaa_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final user = ref.watch(appUserProvider).valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: BrandColors.green,
                    child: Text(
                      user.name.isNotEmpty ? user.name.characters.first : '؟',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          _sectionTitle(context, s.appearance),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (v) => controller.setThemeMode(v!),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(s.themeSystem),
                  secondary: const Icon(Icons.brightness_auto),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(s.themeLight),
                  secondary: const Icon(Icons.light_mode),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(s.themeDark),
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),
          const Divider(),
          _sectionTitle(context, s.language),
          SwitchListTile(
            value: settings.isArabic,
            onChanged: (v) => controller.setArabic(v),
            title: Text(settings.isArabic ? s.arabic : s.english),
            secondary: const Icon(Icons.language),
          ),
          const Divider(),
          _sectionTitle(context, s.notifications),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(s.notifications),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              await NotificationService.instance.requestPermissions();
              final tzName =
                  ref.read(appUserProvider).valueOrNull?.timezone;
              final habits =
                  ref.read(habitsProvider).valueOrNull ?? const [];
              await NotificationService.instance.syncAll(habits, tzName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.done)),
                );
              }
            },
          ),
          const Divider(),
          _sectionTitle(context, s.account),
          ListTile(
            leading: const Icon(Icons.checklist_rtl),
            title: Text(s.myHabits),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mosque),
            title: Text(s.qadaa),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(builder: (context, ref, _) {
                  final count = ref.watch(pendingQadaaCountProvider);
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrandColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  );
                }),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_left),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QadaaScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: Text(s.timezone),
            subtitle: Text(user?.timezone ?? ''),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TimezoneSetupScreen(),
                fullscreenDialog: true,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: BrandColors.danger),
            title: Text(s.logout,
                style: const TextStyle(color: BrandColors.danger)),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('البطولة — v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: BrandColors.green,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}
