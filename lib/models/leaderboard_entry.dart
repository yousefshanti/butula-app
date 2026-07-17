import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.totalPoints,
    required this.lastReportPoints,
    required this.lastReportDate,
    required this.streak,
    this.monthPoints = 0,
    this.monthKey = '',
  });

  final String uid;
  final String name;
  final int totalPoints;
  final int lastReportPoints;
  final String lastReportDate; // YYYY-MM-DD
  final int streak;

  /// Points accumulated in [monthKey] (YYYY-MM) for the month filter.
  final int monthPoints;
  final String monthKey;

  Map<String, dynamic> toMap() => {
        'name': name,
        'totalPoints': totalPoints,
        'lastReportPoints': lastReportPoints,
        'lastReportDate': lastReportDate,
        'streak': streak,
        'monthPoints': monthPoints,
        'monthKey': monthKey,
      };

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> m) =>
      LeaderboardEntry(
        uid: uid,
        name: (m['name'] ?? '') as String,
        totalPoints: (m['totalPoints'] as num?)?.toInt() ?? 0,
        lastReportPoints: (m['lastReportPoints'] as num?)?.toInt() ?? 0,
        lastReportDate: (m['lastReportDate'] ?? '') as String,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
        monthPoints: (m['monthPoints'] as num?)?.toInt() ?? 0,
        monthKey: (m['monthKey'] ?? '') as String,
      );

  static LeaderboardEntry? tryFrom(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return LeaderboardEntry.fromMap(doc.id, data);
  }
}
