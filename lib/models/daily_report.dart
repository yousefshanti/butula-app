import 'package:cloud_firestore/cloud_firestore.dart';

/// A certified daily report — the only official source of leaderboard points.
class DailyReport {
  const DailyReport({
    required this.date,
    this.answers = const {},
    this.totalPoints = 0,
    this.submittedAt,
    this.editCount = 0,
  });

  final String date; // YYYY-MM-DD
  final Map<String, bool> answers;
  final int totalPoints;
  final DateTime? submittedAt;
  final int editCount;

  /// Certified once submitted; a single edit is allowed, then locked.
  bool get isCertified => submittedAt != null;
  bool get isLocked => editCount >= 1;
  bool get canEdit => isCertified && editCount < 1;

  Set<String> get yesKeys =>
      answers.entries.where((e) => e.value).map((e) => e.key).toSet();

  Map<String, dynamic> toMap() => {
        'answers': answers,
        'totalPoints': totalPoints,
        'submittedAt': submittedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(submittedAt!),
        'editCount': editCount,
      };

  factory DailyReport.fromMap(String date, Map<String, dynamic> m) => DailyReport(
        date: date,
        answers: (m['answers'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v == true),
            ) ??
            const {},
        totalPoints: (m['totalPoints'] as num?)?.toInt() ?? 0,
        submittedAt: (m['submittedAt'] as Timestamp?)?.toDate(),
        editCount: (m['editCount'] as num?)?.toInt() ?? 0,
      );
}
