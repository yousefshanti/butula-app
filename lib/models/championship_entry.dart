/// One participant's standing in a monthly championship
/// (championships/{YYYY-MM}/entries/{uid}).
class ChampionshipEntry {
  const ChampionshipEntry({
    required this.uid,
    required this.name,
    required this.points,
    required this.streak,
  });

  final String uid;
  final String name;
  final int points;
  final int streak;

  Map<String, dynamic> toMap() => {
        'name': name,
        'points': points,
        'streak': streak,
      };

  factory ChampionshipEntry.fromMap(String uid, Map<String, dynamic> m) =>
      ChampionshipEntry(
        uid: uid,
        name: (m['name'] ?? '') as String,
        points: (m['points'] as num?)?.toInt() ?? 0,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
      );
}
