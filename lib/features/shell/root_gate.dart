import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import '../auth/timezone_setup_screen.dart';
import 'home_shell.dart';

/// Routes between auth, timezone setup, and the main app based on state.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    // Only show the login screen when we are CERTAIN there is no session:
    // both the auth stream value AND FirebaseAuth.currentUser are null.
    // This guards against a transient null (or error) from authStateChanges()
    // at cold start bouncing a restored session to the login screen.
    // currentUser is used only as a positive "keep the session" signal — never
    // to route *to* login — and is reliable after Firebase.initializeApp().
    bool hasSession(bool streamHasUser) =>
        streamHasUser || ref.read(authServiceProvider).currentUser != null;

    return auth.when(
      loading: () => const _Splash(),
      error: (_, _) =>
          hasSession(false) ? const _SignedInGate() : const LoginScreen(),
      data: (user) =>
          hasSession(user != null) ? const _SignedInGate() : const LoginScreen(),
    );
  }
}

/// Handles the signed-in state: waits for the user document, surfaces errors
/// (instead of hanging), and self-heals a missing document.
class _SignedInGate extends ConsumerWidget {
  const _SignedInGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);

    return appUser.when(
      loading: () => const _Splash(showSlowHint: true),
      error: (error, stack) {
        debugPrint('appUserProvider error: $error\n$stack');
        return _ErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(appUserProvider),
          onLogout: () => ref.read(authServiceProvider).signOut(),
        );
      },
      data: (u) {
        if (u == null) {
          // Read succeeded but the document is missing — create it, then the
          // stream re-emits with the new doc and routes onward.
          return const _EnsureUserDoc();
        }
        if (u.timezone.isEmpty) return const TimezoneSetupScreen();
        return const HomeShell();
      },
    );
  }
}

/// Creates a missing users/{uid} document, showing an error screen if the
/// write itself fails (e.g. permission denied because rules aren't deployed).
class _EnsureUserDoc extends ConsumerStatefulWidget {
  const _EnsureUserDoc();

  @override
  ConsumerState<_EnsureUserDoc> createState() => _EnsureUserDocState();
}

class _EnsureUserDocState extends ConsumerState<_EnsureUserDoc> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _create() async {
    try {
      await ref.read(authServiceProvider).ensureUserDoc();
      // Success: appUserProvider stream will emit the new doc and this widget
      // gets replaced by the parent's data branch.
    } catch (e, st) {
      debugPrint('ensureUserDoc failed: $e\n$st');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        onRetry: () {
          setState(() => _error = null);
          ref.invalidate(appUserProvider);
          _create();
        },
        onLogout: () => ref.read(authServiceProvider).signOut(),
      );
    }
    return const _Splash(showSlowHint: true);
  }
}

/// A clear error screen with retry + logout, plus specific guidance when the
/// failure is a Firestore permission-denied (rules not deployed).
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  bool get _isPermissionDenied =>
      error is FirebaseException &&
      (error as FirebaseException).code == 'permission-denied';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: BrandColors.danger),
                const SizedBox(height: 16),
                Text(
                  _isPermissionDenied
                      ? 'تعذّر الوصول إلى قاعدة البيانات'
                      : 'حدث خطأ أثناء تحميل حسابك',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPermissionDenied
                      ? 'صلاحيات Firestore ترفض القراءة. تأكّد من نشر قواعد '
                          'الأمان (firestore.rules) على مشروع Firebase.'
                      : '$error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash({this.showSlowHint = false});

  /// When true, shows a "taking longer than expected" hint after a delay so a
  /// stalled stream never looks like a permanent hang.
  final bool showSlowHint;

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSlowHint) {
      _timer = Timer(const Duration(seconds: 12), () {
        if (mounted) setState(() => _slow = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.green,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'البطولة',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: BrandColors.gold),
            if (_slow) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'يستغرق وقتًا أطول من المعتاد… تحقّق من اتصالك بالإنترنت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
