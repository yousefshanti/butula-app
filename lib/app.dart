import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings_controller.dart';
import 'core/theme.dart';
import 'features/shell/root_gate.dart';

class ButulaApp extends ConsumerWidget {
  const ButulaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.isArabic ? const Locale('ar') : const Locale('en');

    return MaterialApp(
      title: 'البطولة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Force RTL for Arabic regardless of platform locale.
        return Directionality(
          textDirection:
              settings.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const RootGate(),
    );
  }
}
