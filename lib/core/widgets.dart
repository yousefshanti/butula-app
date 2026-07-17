import 'package:flutter/material.dart';

import 'theme.dart';

/// Live "Total: X/100" bar — green when exactly 100, red otherwise.
class PointsTotalBar extends StatelessWidget {
  const PointsTotalBar({super.key, required this.total, this.label});
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final valid = total == 100;
    final color = valid ? BrandColors.success : BrandColors.danger;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label ?? (context.mounted ? 'المجموع' : ''),
                style: theme.textTheme.labelLarge,
              ),
              Row(
                children: [
                  Icon(valid ? Icons.check_circle : Icons.error_outline,
                      color: color, size: 18),
                  const SizedBox(width: 6),
                  Text('$total/100',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (total / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Persistent warning banner shown when daily points != 100.
class PointsWarningBanner extends StatelessWidget {
  const PointsWarningBanner({
    super.key,
    required this.total,
    this.onAutoDistribute,
    this.onFix,
  });
  final int total;
  final VoidCallback? onAutoDistribute;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    if (total == 100) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandColors.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: BrandColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مجموع نقاط عاداتك اليومية يجب أن يساوي 100 — المجموع الحالي: $total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: BrandColors.danger, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (onAutoDistribute != null || onFix != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onAutoDistribute != null)
                  FilledButton.tonalIcon(
                    onPressed: onAutoDistribute,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('توزيع تلقائي'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                if (onFix != null) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: onFix, child: const Text('تعديل يدوي')),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple centered message with an emoji, for empty states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.action,
  });
  final String emoji;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
