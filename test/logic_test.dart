import 'package:butula/core/scoring.dart';
import 'package:butula/core/suggested_habits.dart';
import 'package:butula/features/habits/habit_controller.dart';
import 'package:butula/features/stats/stats_data.dart';
import 'package:butula/models/chat_message.dart';
import 'package:butula/models/daily_log.dart';
import 'package:butula/models/habit.dart';
import 'package:butula/models/qadaa_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

int _dailyTotal(List<Habit> hs) =>
    hs.where((h) => !h.isPrivate).fold(0, (a, h) => a + h.points);

void main() {
  group('Habit scoring', () {
    test('plain habit scores full points when done', () {
      const h = Habit(id: 'a', name: 'x', points: 20);
      expect(h.scoreFor({'a'}), 20);
      expect(h.scoreFor({}), 0);
    });

    test('private habit never contributes points', () {
      const h = Habit(id: 'p', name: 'x', points: 20, isPrivate: true);
      expect(h.scoreFor({'p'}), 0);
    });

    test('prayers sub-items score proportionally', () {
      final h = Habit(
        id: 'pr',
        name: 'الصلوات',
        points: 30,
        subItems: prayerNames,
      );
      expect(h.logKeys.length, 5);
      expect(h.scoreFor({}), 0);
      // 3 of 5 prayers -> round(30*3/5) = 18
      expect(h.scoreFor({'pr::0', 'pr::1', 'pr::2'}), 18);
      // all 5 -> 30
      expect(
        h.scoreFor({'pr::0', 'pr::1', 'pr::2', 'pr::3', 'pr::4'}),
        30,
      );
    });
  });

  group('Suggested habits', () {
    test('prayers suggestion has five sub-items', () {
      final prayers =
          suggestedHabits.firstWhere((s) => s.subItems.isNotEmpty);
      expect(prayers.subItems.length, 5);
    });

    test('private items are flagged private with zero points', () {
      for (final p in suggestedPrivateItems) {
        expect(p.isPrivate, true);
        expect(p.defaultPoints, 0);
      }
    });
  });

  group('Daily score', () {
    test('sums completed daily habits including partial prayers', () {
      final daily = [
        const Habit(id: 'a', name: 'a', points: 40),
        const Habit(id: 'b', name: 'b', points: 30),
        Habit(id: 'pr', name: 'pr', points: 30, subItems: prayerNames),
      ];
      // a done, b not, 2/5 prayers -> 40 + 0 + round(30*2/5=12) = 52
      final score = dailyScore(daily, {'a', 'pr::0', 'pr::1'});
      expect(score, 52);
    });
  });

  group('Auto-distribute to 100', () {
    test('scales proportional weights to exactly 100', () {
      final habits = [
        const Habit(id: 'a', name: 'a', points: 40),
        const Habit(id: 'b', name: 'b', points: 30),
        const Habit(id: 'c', name: 'c', points: 15),
      ];
      final result = autoDistributeTo100(habits);
      expect(_dailyTotal(result), 100);
    });

    test('equal split when all weights are zero', () {
      final habits = [
        const Habit(id: 'a', name: 'a', points: 0),
        const Habit(id: 'b', name: 'b', points: 0),
        const Habit(id: 'c', name: 'c', points: 0),
      ];
      final result = autoDistributeTo100(habits);
      expect(_dailyTotal(result), 100);
    });

    test('ignores private habits', () {
      final habits = [
        const Habit(id: 'a', name: 'a', points: 50),
        const Habit(id: 'b', name: 'b', points: 50),
        const Habit(id: 'p', name: 'p', points: 0, isPrivate: true),
      ];
      final result = autoDistributeTo100(habits);
      expect(_dailyTotal(result), 100);
      expect(result.firstWhere((h) => h.id == 'p').points, 0);
    });
  });

  group('Habit stats', () {
    const habit = Habit(id: 'h', name: 'h', points: 10);

    test('completion %, current and longest streak', () {
      final end = DateTime(2026, 1, 10);
      final start = DateTime(2026, 1, 1); // 10 days
      // done on days 1,2,3 (longest 3), and 8,9,10 (current 3, ending today)
      final logs = <String, DailyLog>{};
      for (final day in [1, 2, 3, 8, 9, 10]) {
        final k = '2026-01-${day.toString().padLeft(2, '0')}';
        logs[k] = DailyLog(date: k, values: const {'h': true});
      }
      final stats = computeHabitStats(habit, logs, start, end);
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
      expect(stats.completionPct, 60);
    });

    test('empty range yields zeros', () {
      final stats = computeHabitStats(
          habit, {}, DateTime(2026, 1, 1), DateTime(2026, 1, 7));
      expect(stats.completionPct, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
    });
  });

  group('Qadaa entry', () {
    test('pending until made up; round-trips through map', () {
      const pending = QadaaEntry(
          id: 'x', prayerKey: 'الفجر', missedDate: '2026-07-17');
      expect(pending.isPending, true);

      final made = QadaaEntry.fromMap('y', {
        'prayerKey': 'العصر',
        'missedDate': '2026-07-16',
        'madeUpDate': '2026-07-18',
      });
      expect(made.isPending, false);
      expect(made.prayerKey, 'العصر');
      expect(made.toMap()['madeUpDate'], '2026-07-18');
    });
  });

  group('Chat message', () {
    test('parses fields and timestamp from map', () {
      final ts = Timestamp.fromDate(DateTime(2026, 7, 18, 21, 5));
      final m = ChatMessage.fromMap('id1', {
        'senderUid': 'u1',
        'senderName': 'يوسف',
        'text': 'مرحبا',
        'sentAt': ts,
      });
      expect(m.senderUid, 'u1');
      expect(m.senderName, 'يوسف');
      expect(m.text, 'مرحبا');
      expect(m.sentAt, ts.toDate());
    });

    test('toMap carries senderUid for the security rule', () {
      const m = ChatMessage(
          id: '', senderUid: 'u2', senderName: 'n', text: 'hi', sentAt: null);
      expect(m.toMap()['senderUid'], 'u2');
      expect(m.toMap()['text'], 'hi');
    });
  });

  group('Notification id', () {
    test('is stable and within habit range', () {
      final id1 = habitNotificationId('abc');
      final id2 = habitNotificationId('abc');
      expect(id1, id2);
      expect(id1 >= 1000, true);
    });
  });
}
