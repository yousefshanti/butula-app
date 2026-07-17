import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/daily_report.dart';
import '../habits/habit_controller.dart';
import 'report_flow_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final loc = ref.watch(tzLocationProvider);
    final total = ref.watch(dailyPointsTotalProvider);
    final pointsValid = total == 100;
    final window = ReportWindow.now(loc);
    final reportAsync = ref.watch(reportProvider(window.reportDate));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.certifiedReport)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(icon: Icons.info_outline, text: s.reportWindowInfo),
            const SizedBox(height: 12),
            Text('${s.today}: ${window.reportDate}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: !pointsValid
                  ? _blocked(s, total)
                  : !window.isOpen
                      ? _closed(s, window, loc)
                      : reportAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('${s.error}\n$e')),
                          data: (report) =>
                              _open(s, window.reportDate, report),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocked(dynamic s, int total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.block, size: 64, color: BrandColors.danger),
        const SizedBox(height: 16),
        PointsWarningBanner(
          total: total,
          onAutoDistribute: () =>
              ref.read(habitControllerProvider).applyAutoDistribute(),
        ),
        const SizedBox(height: 8),
        const FilledButton(onPressed: null, child: Text('اعتماد التقرير')),
      ],
    );
  }

  Widget _closed(dynamic s, ReportWindow window, tz.Location loc) {
    final remaining = window.untilOpen(loc);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock, size: 64, color: BrandColors.gold),
          const SizedBox(height: 16),
          Text(s.reportClosed, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(s.reportOpensIn, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            formatDuration(remaining),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: BrandColors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _open(dynamic s, String date, DailyReport? report) {
    if (report != null && report.isCertified) {
      return _certified(s, date, report);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📝', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(s.reviewAnswers,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _startFlow(date, isEdit: false),
            icon: const Icon(Icons.assignment_turned_in),
            label: Text(s.certifyReport),
          ),
        ],
      ),
    );
  }

  Widget _certified(dynamic s, String date, DailyReport report) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BrandColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified, size: 48, color: BrandColors.success),
              const SizedBox(height: 8),
              Text(s.reportCertified, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${report.totalPoints}/100',
                  style: theme.textTheme.displaySmall?.copyWith(
                      color: BrandColors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (report.canEdit)
          FilledButton.tonalIcon(
            onPressed: () => _startFlow(date, isEdit: true),
            icon: const Icon(Icons.edit),
            label: Text('${s.editReport} — ${s.oneEditLeft}'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 18),
              const SizedBox(width: 8),
              Text(s.reportLocked),
            ],
          ),
      ],
    );
  }

  void _startFlow(String date, {required bool isEdit}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportFlowScreen(date: date, isEdit: isEdit),
    ));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: BrandColors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
