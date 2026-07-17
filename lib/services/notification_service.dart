import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Local notifications for report reminders and per-habit reminders.
/// All notifications are local (work offline). iOS + Android supported.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int reportReminderId8pm = 0;
  static const int reportReminderId10pm = 1;

  static const _reportChannel = AndroidNotificationChannel(
    'report_channel',
    'تذكير التقرير',
    description: 'تذكير باعتماد التقرير اليومي',
    importance: Importance.high,
  );
  static const _habitChannel = AndroidNotificationChannel(
    'habit_channel',
    'تذكير العادات',
    description: 'تذكيرات العادات الفردية',
    importance: Importance.defaultImportance,
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_reportChannel);
    await androidImpl?.createNotificationChannel(_habitChannel);
    _ready = true;
  }

  /// Requests notification permission on both platforms (first launch).
  Future<bool> requestPermissions() async {
    await init();
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (androidImpl != null) {
      granted =
          (await androidImpl.requestNotificationsPermission()) ?? granted;
    }
    if (iosImpl != null) {
      granted = (await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          granted;
    }
    return granted;
  }

  tz.Location _location(String? ianaName) {
    if (ianaName == null || ianaName.isEmpty) return tz.local;
    try {
      return tz.getLocation(ianaName);
    } catch (_) {
      return tz.local;
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute, tz.Location loc) {
    final now = tz.TZDateTime.now(loc);
    var scheduled = tz.TZDateTime(loc, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required AndroidNotificationDetails android,
    required String? timezoneName,
  }) async {
    await init();
    final loc = _location(timezoneName);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute, loc),
        NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('schedule failed for $id: $e');
    }
  }

  /// Report reminders at 8PM and 10PM local time (user's timezone).
  Future<void> scheduleReportReminders(String? timezoneName) async {
    final android = AndroidNotificationDetails(
      _reportChannel.id,
      _reportChannel.name,
      channelDescription: _reportChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _scheduleDaily(
      id: reportReminderId8pm,
      title: 'حان وقت التقرير 📝',
      body: 'اعتمد تقريرك اليومي الآن ونافس أصدقاءك!',
      hour: 20,
      minute: 0,
      android: android,
      timezoneName: timezoneName,
    );
    await _scheduleDaily(
      id: reportReminderId10pm,
      title: 'تذكير أخير ⏰',
      body: 'لم تعتمد تقريرك بعد — النافذة تُغلق 7 صباحًا.',
      hour: 22,
      minute: 0,
      android: android,
      timezoneName: timezoneName,
    );
  }

  /// Cancels tonight's 10PM reminder (called after the report is certified).
  Future<void> cancelTonight10pmReminder() async {
    await init();
    await _plugin.cancel(reportReminderId10pm);
  }

  Future<void> scheduleHabitReminder(Habit habit, String? timezoneName) async {
    if (!habit.reminderEnabled || habit.reminderMinutes == null) {
      await cancelHabitReminder(habit.id);
      return;
    }
    final android = AndroidNotificationDetails(
      _habitChannel.id,
      _habitChannel.name,
      channelDescription: _habitChannel.description,
    );
    await _scheduleDaily(
      id: habitNotificationId(habit.id),
      title: '${habit.emoji} ${habit.name}',
      body: 'تذكير بعادتك اليومية',
      hour: habit.reminderMinutes! ~/ 60,
      minute: habit.reminderMinutes! % 60,
      android: android,
      timezoneName: timezoneName,
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await init();
    await _plugin.cancel(habitNotificationId(habitId));
  }

  /// Re-syncs all reminders (report + each habit's optional reminder).
  Future<void> syncAll(List<Habit> habits, String? timezoneName) async {
    await scheduleReportReminders(timezoneName);
    for (final h in habits) {
      await scheduleHabitReminder(h, timezoneName);
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
