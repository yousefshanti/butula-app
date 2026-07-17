import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/app_user.dart';
import '../models/daily_log.dart';
import '../models/daily_report.dart';
import '../models/chat_message.dart';
import '../models/habit.dart';
import '../models/leaderboard_entry.dart';
import '../models/qadaa_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// ---- Firebase singletons ----
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>((ref) => AuthService(
      ref.watch(firebaseAuthProvider),
      ref.watch(firestoreProvider),
    ));

// ---- Auth state ----
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authState(),
);

final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

/// Firestore data access for the signed-in user, or null when logged out.
final firestoreServiceProvider = Provider<FirestoreService?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return FirestoreService(ref.watch(firestoreProvider), uid);
});

// ---- User doc ----
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.userStream();
});

/// The user's timezone location (falls back to device local / UTC).
final tzLocationProvider = Provider<tz.Location>((ref) {
  final name = ref.watch(appUserProvider).valueOrNull?.timezone;
  if (name == null || name.isEmpty) {
    try {
      return tz.local;
    } catch (_) {
      return tz.UTC;
    }
  }
  try {
    return tz.getLocation(name);
  } catch (_) {
    return tz.local;
  }
});

// ---- Habits ----
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.habitsStream();
});

final dailyHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  return habits.where((h) => h.isDaily).toList();
});

/// Sum of point weights of all daily, non-private habits (the 100-point rule).
final dailyPointsTotalProvider = Provider<int>((ref) {
  final daily = ref.watch(dailyHabitsProvider);
  return daily
      .where((h) => !h.isPrivate)
      .fold<int>(0, (acc, h) => acc + h.points);
});

final pointsValidProvider =
    Provider<bool>((ref) => ref.watch(dailyPointsTotalProvider) == 100);

// ---- Logs ----
final logProvider =
    StreamProvider.family<DailyLog, String>((ref, date) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return Stream.value(DailyLog.empty(date));
  return svc.logStream(date);
});

// ---- Reports ----
final reportProvider =
    StreamProvider.family<DailyReport?, String>((ref, date) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.reportStream(date);
});

// ---- Qadaa (missed prayers) ----
final qadaaProvider = StreamProvider<List<QadaaEntry>>((ref) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.qadaaStream();
});

/// Count of pending (not-yet-made-up) missed prayers.
final pendingQadaaCountProvider = Provider<int>((ref) {
  final all = ref.watch(qadaaProvider).valueOrNull ?? const [];
  return all.where((q) => q.isPending).length;
});

// ---- Group chat ----
/// Number of latest messages to load; grows by 50 when scrolling up.
final chatLimitProvider = StateProvider<int>((_) => 50);

final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.chatStream(ref.watch(chatLimitProvider));
});

final latestChatMessageProvider = StreamProvider<ChatMessage?>((ref) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.latestChatStream();
});

/// True when the newest message (from someone else) is newer than the user's
/// last chat-read time — drives the unread badge on the chat tab.
final hasUnreadChatProvider = Provider<bool>((ref) {
  final latest = ref.watch(latestChatMessageProvider).valueOrNull;
  final uid = ref.watch(currentUidProvider);
  if (latest == null || latest.sentAt == null) return false;
  if (latest.senderUid == uid) return false;
  final lastRead = ref.watch(appUserProvider).valueOrNull?.chatLastReadAt;
  if (lastRead == null) return true;
  return latest.sentAt!.isAfter(lastRead);
});

// ---- Leaderboard ----
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final svc = ref.watch(firestoreServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.leaderboardStream();
});
