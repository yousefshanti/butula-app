import 'package:butula/core/date_utils.dart';
import 'package:butula/core/scoring.dart';
import 'package:butula/models/app_version_config.dart';
import 'package:butula/core/suggested_habits.dart';
import 'package:butula/features/settings/data_export.dart';
import 'package:butula/models/daily_report.dart';
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
  group('Data export workbook', () {
    test('has the four Arabic sheets, not the default, with header + rows', () {
      final excel = buildExportWorkbook(
        habits: [
          const Habit(id: 'h1', name: 'قراءة', points: 20),
          Habit(id: 'pr', name: 'الصلوات', points: 30, subItems: prayerNames),
          const Habit(id: 'h2', name: 'محذوفة', points: 0, deleted: true),
        ],
        logs: [
          const DailyLog(
            date: '2026-07-17',
            values: {'h1': true, 'pr::0': false},
            editedLater: true,
          ),
        ],
        reports: [
          DailyReport(
            date: '2026-07-17',
            totalPoints: 62,
            submittedAt: DateTime(2026, 7, 17, 21, 30),
            editCount: 1,
          ),
        ],
        qadaa: const [
          QadaaEntry(id: 'q', prayerKey: 'الفجر', missedDate: '2026-07-17'),
        ],
      );

      final names = excel.sheets.keys.toSet();
      expect(names.contains(sheetHabits), true);
      expect(names.contains(sheetLogs), true);
      expect(names.contains(sheetReports), true);
      expect(names.contains(sheetQadaa), true);
      expect(names.contains('Sheet1'), false);

      // Habits: header + 3 habit rows.
      expect(excel.sheets[sheetHabits]!.maxRows, 4);
      // Logs: header + 2 answered entries.
      expect(excel.sheets[sheetLogs]!.maxRows, 3);
      // Reports & qadaa: header + 1 row each.
      expect(excel.sheets[sheetReports]!.maxRows, 2);
      expect(excel.sheets[sheetQadaa]!.maxRows, 2);

      // Saving produces bytes.
      expect(excel.save(), isNotNull);
    });
  });

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

  group('App day boundary (3 AM)', () {
    test('before 3 AM belongs to the previous calendar day', () {
      // 1:30 AM on Jul 19 -> app-day Jul 18
      expect(appDayKeyOf(DateTime(2026, 7, 19, 1, 30)), '2026-07-18');
      // 2:59 AM -> still previous day
      expect(appDayKeyOf(DateTime(2026, 7, 19, 2, 59)), '2026-07-18');
    });

    test('3 AM onward belongs to the current calendar day', () {
      expect(appDayKeyOf(DateTime(2026, 7, 19, 3, 0)), '2026-07-19');
      expect(appDayKeyOf(DateTime(2026, 7, 19, 12, 0)), '2026-07-19');
      expect(appDayKeyOf(DateTime(2026, 7, 19, 23, 59)), '2026-07-19');
    });
  });

  group('Date label + shift', () {
    test('shiftDayKey moves across month boundaries', () {
      expect(shiftDayKey('2026-07-31', 1), '2026-08-01');
      expect(shiftDayKey('2026-08-01', -1), '2026-07-31');
    });

    test('Arabic day label uses weekday + Arabic-Indic day + month', () {
      // 2026-07-17 is a Friday.
      expect(dayLabel('2026-07-17', isArabic: true), 'الجمعة ١٧ يوليو');
      expect(dayLabel('2026-07-17', isArabic: false), 'Friday 17 July');
    });
  });

  group('Binary log', () {
    test('absent or false key is not done; true key is done', () {
      const log = DailyLog(date: '2026-07-18', values: {'a': true, 'b': false});
      expect(log.isDone('a'), true);
      expect(log.isDone('b'), false);
      expect(log.isDone('c'), false); // absent -> No
      expect(log.doneKeys, {'a'});
    });
  });

  group('App version config', () {
    test('parses fields with sane defaults', () {
      final c = AppVersionConfig.fromMap({
        'latestBuild': 5,
        'apkUrl': 'https://example.com/app.apk',
        'required': true,
      });
      expect(c.latestBuild, 5);
      expect(c.apkUrl, 'https://example.com/app.apk');
      expect(c.required, true);

      final empty = AppVersionConfig.fromMap({});
      expect(empty.latestBuild, 0);
      expect(empty.apkUrl, '');
      expect(empty.required, false);
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
