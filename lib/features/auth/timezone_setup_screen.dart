import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/app_providers.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../services/notification_service.dart';

class TimezoneSetupScreen extends ConsumerStatefulWidget {
  const TimezoneSetupScreen({super.key});

  @override
  ConsumerState<TimezoneSetupScreen> createState() =>
      _TimezoneSetupScreenState();
}

class _TimezoneSetupScreenState extends ConsumerState<TimezoneSetupScreen> {
  String? _selected;
  String? _detected;
  bool _saving = false;
  final _search = TextEditingController();
  late final List<String> _all;

  @override
  void initState() {
    super.initState();
    _all = tz.timeZoneDatabase.locations.keys.toList()..sort();
    _detect();
  }

  Future<void> _detect() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      setState(() {
        _detected = name;
        _selected ??= name;
      });
    } catch (_) {
      setState(() => _selected ??= 'Asia/Gaza');
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tzName = _selected;
    if (tzName == null) return;
    setState(() => _saving = true);
    final svc = ref.read(firestoreServiceProvider);
    await svc?.updateUser(timezone: tzName);
    await NotificationService.instance.scheduleReportReminders(tzName);
    // Root gate will re-route once the user doc updates.
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final query = _search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _all
        : _all.where((t) => t.toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.pickTimezone)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.timezoneHint, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                if (_detected != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: BrandColors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${s.detected}: $_detected',
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'ابحث… (مثال: Gaza, Cairo, New_York)',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RadioGroup<String>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final tzName = filtered[i];
                  return RadioListTile<String>(
                    value: tzName,
                    title: Text(tzName),
                    dense: true,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: (_selected == null || _saving) ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.saveContinue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
