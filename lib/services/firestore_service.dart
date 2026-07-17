import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/date_utils.dart';
import '../models/app_user.dart';
import '../models/daily_log.dart';
import '../models/daily_report.dart';
import '../models/chat_message.dart';
import '../models/habit.dart';
import '../models/leaderboard_entry.dart';
import '../models/qadaa_entry.dart';

/// All Firestore reads/writes for a signed-in user. Cloud Firestore only.
class FirestoreService {
  FirestoreService(this._db, this.uid);
  final FirebaseFirestore _db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _habits =>
      _userDoc.collection('habits');
  CollectionReference<Map<String, dynamic>> get _logs =>
      _userDoc.collection('logs');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _userDoc.collection('reports');
  CollectionReference<Map<String, dynamic>> get _qadaa =>
      _userDoc.collection('qadaa');
  DocumentReference<Map<String, dynamic>> get _leaderboardDoc =>
      _db.collection('leaderboard').doc(uid);

  // ---- User ----
  Stream<AppUser?> userStream() => _userDoc.snapshots().map(
        (d) => d.exists ? AppUser.fromMap(uid, d.data()!) : null,
      );

  Future<void> updateUser({String? name, String? timezone}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (timezone != null) data['timezone'] = timezone;
    if (data.isEmpty) return;
    await _userDoc.set(data, SetOptions(merge: true));
    if (name != null) {
      await _leaderboardDoc.set({'name': name}, SetOptions(merge: true));
    }
  }

  // ---- Habits ----
  Stream<List<Habit>> habitsStream() =>
      _habits.orderBy('order').snapshots().map(
            (s) => s.docs.map((d) => Habit.fromMap(d.id, d.data())).toList(),
          );

  Future<Habit> addHabit(Habit habit) async {
    final ref = _habits.doc();
    final withId = habit.copyWith(id: ref.id);
    await ref.set(withId.toMap());
    return withId;
  }

  Future<void> addHabits(List<Habit> habits) async {
    final batch = _db.batch();
    for (final h in habits) {
      final ref = _habits.doc();
      batch.set(ref, h.copyWith(id: ref.id).toMap());
    }
    await batch.commit();
  }

  Future<void> updateHabit(Habit habit) =>
      _habits.doc(habit.id).set(habit.toMap());

  Future<void> deleteHabit(String habitId) => _habits.doc(habitId).delete();

  Future<void> reorderHabits(List<Habit> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_habits.doc(ordered[i].id), {'order': i});
    }
    await batch.commit();
  }

  // ---- Logs ----
  Stream<DailyLog> logStream(String date) => _logs.doc(date).snapshots().map(
        (d) => d.exists ? DailyLog.fromMap(date, d.data()!) : DailyLog.empty(date),
      );

  Future<void> setLogValue(
    String date,
    String key,
    bool value, {
    bool markEdited = false,
  }) async {
    final data = <String, dynamic>{key: value};
    if (markEdited) data['editedLater'] = true;
    await _logs.doc(date).set(data, SetOptions(merge: true));
  }

  Future<void> mergeLog(String date, Map<String, bool> values,
      {bool markEdited = false}) async {
    final data = <String, dynamic>{...values};
    if (markEdited) data['editedLater'] = true;
    await _logs.doc(date).set(data, SetOptions(merge: true));
  }

  Future<DailyLog> getLog(String date) async {
    final d = await _logs.doc(date).get();
    return d.exists ? DailyLog.fromMap(date, d.data()!) : DailyLog.empty(date);
  }

  Future<List<DailyLog>> logsInRange(String startKey, String endKey) async {
    final snap = await _logs
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .get();
    return snap.docs.map((d) => DailyLog.fromMap(d.id, d.data())).toList();
  }

  // ---- Reports ----
  Stream<DailyReport?> reportStream(String date) =>
      _reports.doc(date).snapshots().map(
            (d) => d.exists ? DailyReport.fromMap(date, d.data()!) : null,
          );

  Future<DailyReport?> getReport(String date) async {
    final d = await _reports.doc(date).get();
    return d.exists ? DailyReport.fromMap(date, d.data()!) : null;
  }

  Future<List<DailyReport>> reportsInRange(String startKey, String endKey) async {
    final snap = await _reports
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .get();
    return snap.docs.map((d) => DailyReport.fromMap(d.id, d.data())).toList();
  }

  /// Certifies a report and pushes points to the leaderboard.
  /// [isEdit] increments editCount; the caller enforces the single-edit rule.
  Future<void> certifyReport({
    required String date,
    required Map<String, bool> answers,
    required int totalPoints,
    required String userName,
    required bool isEdit,
  }) async {
    final existing = await getReport(date);
    final previousPoints = existing?.totalPoints ?? 0;
    final editCount = isEdit ? (existing?.editCount ?? 0) + 1 : 0;

    await _reports.doc(date).set({
      'answers': answers,
      'totalPoints': totalPoints,
      'submittedAt': FieldValue.serverTimestamp(),
      'editCount': editCount,
    });

    final streak = await _computeStreak(date);
    final monthKey = monthKeyOf(parseDateKey(date));

    await _db.runTransaction((tx) async {
      final lbSnap = await tx.get(_leaderboardDoc);
      final data = lbSnap.data() ?? {};
      final prevTotal = (data['totalPoints'] as num?)?.toInt() ?? 0;
      final prevMonthKey = (data['monthKey'] ?? '') as String;
      final prevMonthPoints = (data['monthPoints'] as num?)?.toInt() ?? 0;

      // Adjust total by the delta (handles edits that change the score).
      final newTotal = prevTotal - previousPoints + totalPoints;
      final sameMonth = prevMonthKey == monthKey;
      final newMonthPoints = sameMonth
          ? prevMonthPoints - previousPoints + totalPoints
          : totalPoints;

      tx.set(_leaderboardDoc, {
        'name': userName,
        'totalPoints': newTotal,
        'lastReportPoints': totalPoints,
        'lastReportDate': date,
        'streak': streak,
        'monthKey': monthKey,
        'monthPoints': newMonthPoints,
      }, SetOptions(merge: true));
    });
  }

  /// Consecutive days ending at [date] that have a certified report.
  Future<int> _computeStreak(String date) async {
    final end = parseDateKey(date);
    final start = end.subtract(const Duration(days: 90));
    final reports = await reportsInRange(dateKey(start), date);
    final certified = reports
        .where((r) => r.isCertified || r.date == date)
        .map((r) => r.date)
        .toSet();
    certified.add(date); // the one we just wrote (serverTimestamp not yet read)

    var streak = 0;
    var cursor = end;
    while (certified.contains(dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---- Qadaa (missed prayers) ----
  Stream<List<QadaaEntry>> qadaaStream() => _qadaa.snapshots().map(
        (s) => s.docs.map((d) => QadaaEntry.fromMap(d.id, d.data())).toList(),
      );

  /// Adds a missed-prayer entry, unless one already exists for this
  /// prayer+date (pending or already made up) — keeps it idempotent.
  Future<void> addMissedPrayer(String prayerKey, String missedDate) async {
    final existing = await _qadaa
        .where('prayerKey', isEqualTo: prayerKey)
        .where('missedDate', isEqualTo: missedDate)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _qadaa.add({
      'prayerKey': prayerKey,
      'missedDate': missedDate,
      'madeUpDate': null,
    });
  }

  /// Removes PENDING entries for this prayer+date (used when a prayer flips
  /// from No to Yes). Never touches entries already marked as made up.
  Future<void> removePendingMissedPrayer(
      String prayerKey, String missedDate) async {
    final snap = await _qadaa
        .where('prayerKey', isEqualTo: prayerKey)
        .where('missedDate', isEqualTo: missedDate)
        .where('madeUpDate', isNull: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  /// Adds or removes a qadaa entry to match a prayer's logged state.
  Future<void> reconcilePrayerQadaa({
    required String prayerKey,
    required String missedDate,
    required bool done,
  }) {
    return done
        ? removePendingMissedPrayer(prayerKey, missedDate)
        : addMissedPrayer(prayerKey, missedDate);
  }

  Future<void> markQadaaMadeUp(String id, String madeUpDate) =>
      _qadaa.doc(id).update({'madeUpDate': madeUpDate});

  Future<void> undoQadaaMadeUp(String id) =>
      _qadaa.doc(id).update({'madeUpDate': null});

  // ---- Group chat (single shared room) ----
  CollectionReference<Map<String, dynamic>> get _chat => _db.collection('chat');

  /// Latest [limit] messages, oldest-first for display. Realtime.
  Stream<List<ChatMessage>> chatStream(int limit) => _chat
      .orderBy('sentAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ChatMessage.fromMap(d.id, d.data()))
          .toList()
          .reversed
          .toList());

  /// The single most recent message (for the unread badge).
  Stream<ChatMessage?> latestChatStream() => _chat
      .orderBy('sentAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty
          ? null
          : ChatMessage.fromMap(s.docs.first.id, s.docs.first.data()));

  Future<void> sendChatMessage(String text, String senderName) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _chat.add(ChatMessage(
      id: '',
      senderUid: uid,
      senderName: senderName,
      text: trimmed,
      sentAt: null,
    ).toMap());
  }

  Future<void> markChatRead() =>
      _userDoc.set({'chatLastReadAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  // ---- Leaderboard ----
  Stream<List<LeaderboardEntry>> leaderboardStream() =>
      _db.collection('leaderboard').snapshots().map(
            (s) => s.docs
                .map(LeaderboardEntry.tryFrom)
                .whereType<LeaderboardEntry>()
                .toList(),
          );
}
