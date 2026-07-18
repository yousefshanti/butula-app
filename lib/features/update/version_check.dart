import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_providers.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';

/// Reads app_config/version and, if the installed build is older, shows an
/// Arabic update dialog (dismissible unless required). Best-effort; never throws.
Future<void> checkForUpdate(BuildContext context, WidgetRef ref) async {
  try {
    final svc = ref.read(firestoreServiceProvider);
    if (svc == null) return;
    final config = await svc.getVersionConfig();
    if (config == null || config.apkUrl.isEmpty) return;

    final info = await PackageInfo.fromPlatform();
    final installed = int.tryParse(info.buildNumber) ?? 0;
    if (installed >= config.latestBuild) return;

    if (!context.mounted) return;
    final s = ref.read(stringsProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: !config.required,
      builder: (dialogContext) => PopScope(
        canPop: !config.required,
        child: AlertDialog(
          title: Text(s.updateTitle),
          content: Text(config.required ? s.updateRequiredBody : s.updateBody),
          actions: [
            if (!config.required)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(s.later),
              ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BrandColors.green),
              onPressed: () async {
                final uri = Uri.tryParse(config.apkUrl);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(s.updateNow),
            ),
          ],
        ),
      ),
    );
  } catch (_) {
    // Best-effort — a failed check never blocks the app.
  }
}
