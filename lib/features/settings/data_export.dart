import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/date_utils.dart';
import '../../models/daily_log.dart';
import '../../models/daily_report.dart';
import '../../models/habit.dart';
import '../../models/qadaa_entry.dart';
import '../../services/firestore_service.dart';

/// Arabic sheet names.
const sheetHabits = 'العادات';
const sheetLogs = 'السجل اليومي';
const sheetReports = 'التقارير المعتمدة';
const sheetQadaa = 'القضاء';

String _typeLabel(HabitType t) => switch (t) {
      HabitType.daily => 'يومي',
      HabitType.weekly => 'أسبوعي',
      HabitType.monthly => 'شهري',
    };

String _fmtDateTime(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${dateKey(l)} ${p(l.hour)}:${p(l.minute)}';
}

/// Builds the multi-sheet workbook (pure — no I/O, so it is unit-testable).
Excel buildExportWorkbook({
  required List<Habit> habits,
  required List<DailyLog> logs,
  required List<DailyReport> reports,
  required List<QadaaEntry> qadaa,
}) {
  // Map every log-key to a readable habit (or prayer) name.
  final nameByKey = <String, String>{};
  for (final h in habits) {
    if (h.hasSubItems) {
      for (var i = 0; i < h.subItems.length; i++) {
        nameByKey['${h.id}::$i'] = '${h.name} — ${h.subItems[i]}';
      }
    } else {
      nameByKey[h.id] = h.name;
    }
  }

  final excel = Excel.createExcel();

  // 1) العادات
  excel.appendRow(sheetHabits, [
    TextCellValue('الاسم'),
    TextCellValue('الأيقونة'),
    TextCellValue('النقاط'),
    TextCellValue('النوع'),
    TextCellValue('خاصة؟'),
    TextCellValue('الحالة'),
  ]);
  for (final h in habits) {
    excel.appendRow(sheetHabits, [
      TextCellValue(h.name),
      TextCellValue(h.iconCodePoint != null ? '(أيقونة)' : h.emoji),
      IntCellValue(h.points),
      TextCellValue(_typeLabel(h.type)),
      TextCellValue(h.isPrivate ? 'نعم' : 'لا'),
      TextCellValue(h.deleted ? 'محذوفة' : 'نشطة'),
    ]);
  }

  // 2) السجل اليومي — one row per answered habit entry per day.
  excel.appendRow(sheetLogs, [
    TextCellValue('التاريخ'),
    TextCellValue('العادة'),
    TextCellValue('أُنجزت؟'),
    TextCellValue('عُدّل لاحقًا؟'),
  ]);
  for (final log in logs) {
    final entries = log.values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in entries) {
      excel.appendRow(sheetLogs, [
        TextCellValue(log.date),
        TextCellValue(nameByKey[e.key] ?? '(عادة سابقة)'),
        TextCellValue(e.value ? 'نعم' : 'لا'),
        TextCellValue(log.editedLater ? 'نعم' : 'لا'),
      ]);
    }
  }

  // 3) التقارير المعتمدة — one row per day.
  excel.appendRow(sheetReports, [
    TextCellValue('التاريخ'),
    TextCellValue('مجموع النقاط'),
    TextCellValue('وقت الإرسال'),
    TextCellValue('عُدّل؟'),
  ]);
  for (final r in reports) {
    excel.appendRow(sheetReports, [
      TextCellValue(r.date),
      IntCellValue(r.totalPoints),
      TextCellValue(_fmtDateTime(r.submittedAt)),
      TextCellValue(r.editCount > 0 ? 'نعم' : 'لا'),
    ]);
  }

  // 4) القضاء
  excel.appendRow(sheetQadaa, [
    TextCellValue('الصلاة'),
    TextCellValue('تاريخ الفوات'),
    TextCellValue('تاريخ القضاء'),
  ]);
  for (final q in qadaa) {
    excel.appendRow(sheetQadaa, [
      TextCellValue(q.prayerKey),
      TextCellValue(q.missedDate),
      TextCellValue(q.madeUpDate ?? 'لم تُقضَ بعد'),
    ]);
  }

  // Remove the auto-created default sheet.
  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }
  return excel;
}

/// Gathers ALL of the signed-in user's own data and writes a multi-sheet
/// .xlsx file to a temporary location, returning it for sharing.
Future<File> exportUserDataToXlsx(FirestoreService svc) async {
  final (habits, logs, reports, qadaa) = await (
    svc.allHabitsRaw(),
    svc.allLogs(),
    svc.allReports(),
    svc.allQadaa(),
  ).wait;

  final excel = buildExportWorkbook(
    habits: habits,
    logs: logs,
    reports: reports,
    qadaa: qadaa,
  );
  final bytes = excel.save();
  if (bytes == null) {
    throw Exception('تعذّر إنشاء ملف Excel');
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/butula_export_${dateKey(DateTime.now())}.xlsx');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
