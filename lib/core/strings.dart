import 'package:flutter/widgets.dart';

/// Bilingual strings. Arabic is primary; English secondary.
/// Access via `ref.watch(stringsProvider)` (see core/app_providers.dart).
class AppStrings {
  const AppStrings({required this.isArabic});
  final bool isArabic;

  String _t(String ar, String en) => isArabic ? ar : en;

  Locale get locale => isArabic ? const Locale('ar') : const Locale('en');

  // App
  String get appName => _t('البطولة', 'Al-Butula');

  // Navigation
  String get navToday => _t('اليوم', 'Today');
  String get navReport => _t('التقرير', 'Report');
  String get navStats => _t('الإحصائيات', 'Stats');
  String get navLeaderboard => _t('المتصدرون', 'Leaderboard');
  String get navSettings => _t('الإعدادات', 'Settings');

  // Auth
  String get login => _t('تسجيل الدخول', 'Log in');
  String get signup => _t('إنشاء حساب', 'Sign up');
  String get email => _t('البريد الإلكتروني', 'Email');
  String get password => _t('كلمة المرور', 'Password');
  String get displayName => _t('الاسم الظاهر', 'Display name');
  String get noAccount => _t('ليس لديك حساب؟ أنشئ واحدًا', "Don't have an account? Sign up");
  String get haveAccount => _t('لديك حساب؟ سجّل الدخول', 'Have an account? Log in');
  String get logout => _t('تسجيل الخروج', 'Log out');
  String get authWelcome => _t('نافس أصدقاءك في العادات اليومية', 'Compete with friends on daily habits');

  // Timezone
  String get pickTimezone => _t('اختر منطقتك الزمنية', 'Pick your timezone');
  String get timezone => _t('المنطقة الزمنية', 'Timezone');
  String get timezoneHint => _t(
      'تُستخدم لتحديد نافذة التقرير (8 مساءً – 7 صباحًا) بتوقيتك.',
      'Used to set your report window (8PM–7AM) in your local time.');
  String get detected => _t('المكتشفة تلقائيًا', 'Auto-detected');
  String get saveContinue => _t('حفظ ومتابعة', 'Save & continue');

  // Habits
  String get myHabits => _t('عاداتي', 'My habits');
  String get addHabit => _t('إضافة عادة', 'Add habit');
  String get editHabit => _t('تعديل العادة', 'Edit habit');
  String get newHabit => _t('عادة جديدة', 'New habit');
  String get habitName => _t('اسم العادة', 'Habit name');
  String get points => _t('النقاط', 'Points');
  String get icon => _t('الأيقونة', 'Icon');
  String get type => _t('النوع', 'Type');
  String get daily => _t('يومي', 'Daily');
  String get weekly => _t('أسبوعي', 'Weekly');
  String get monthly => _t('شهري', 'Monthly');
  String get save => _t('حفظ', 'Save');
  String get delete => _t('حذف', 'Delete');
  String get cancel => _t('إلغاء', 'Cancel');
  String get confirm => _t('تأكيد', 'Confirm');
  String get reorder => _t('إعادة الترتيب', 'Reorder');
  String get suggestedHabits => _t('عادات مقترحة', 'Suggested habits');
  String get addSelected => _t('إضافة المحدد', 'Add selected');
  String get privateItem => _t('عنصر خاص (بدون نقاط)', 'Private item (no points)');
  String get privateHint => _t(
      'العناصر الخاصة لا تظهر للآخرين ولا تُحتسب في أي مجموع.',
      'Private items are never shown to others and excluded from all totals.');
  String get chooseWeekdays => _t('اختر الأيام', 'Choose weekdays');
  String get timesPerWeek => _t('مرات في الأسبوع', 'Times per week');
  String get timesPerMonth => _t('مرات في الشهر', 'Times per month');
  String get dayOfMonth => _t('يوم من الشهر', 'Day of month');
  String get emptyHabitsTitle => _t('لنبنِ جدول عاداتك', "Let's build your habit table");
  String get emptyHabitsBody => _t(
      'ابدأ بإضافة عاداتك اليومية. مجموع نقاط العادات اليومية يجب أن يساوي 100.',
      'Start by adding your daily habits. Daily points must total exactly 100.');
  String get startFromSuggested => _t('ابدأ من المقترحات', 'Start from suggestions');
  String get startFromScratch => _t('ابدأ من الصفر', 'Start from scratch');
  String get reminder => _t('تذكير', 'Reminder');
  String get enableReminder => _t('تفعيل التذكير', 'Enable reminder');
  String get reminderTime => _t('وقت التذكير', 'Reminder time');

  // 100-point rule
  String totalPoints(int t) => _t('المجموع: $t/100', 'Total: $t/100');
  String get autoDistribute => _t('توزيع تلقائي', 'Auto-distribute');
  String get pointsMustBe100 => _t(
      'مجموع نقاط العادات اليومية يجب أن يساوي 100.',
      'Daily habit points must total exactly 100.');
  String blockReport(int t) => _t(
      'مجموع نقاط عاداتك اليومية يجب أن يساوي 100 — المجموع الحالي: $t',
      'Your daily habit points must total 100 — current total: $t');
  String get weeklyMonthlyNote => _t(
      'العادات الأسبوعية/الشهرية لها نقاطها الخاصة ولا تُحتسب ضمن الـ100 ولا في المتصدرين.',
      'Weekly/monthly habits have their own points, not part of the 100 or the leaderboard.');

  // Logging
  String get today => _t('اليوم', 'Today');
  String scoreOf100(int s) => _t('$s/100', '$s/100');
  String get dailyScore => _t('نتيجة اليوم', "Today's score");
  String get editedLater => _t('عُدّل لاحقًا', 'Edited later');
  String get calendar => _t('التقويم', 'Calendar');
  String get noHabitsToday => _t('لا توجد عادات يومية بعد', 'No daily habits yet');

  // Prayers
  String get prayers => _t('الصلوات الخمس', 'The five prayers');

  // Report
  String get certifiedReport => _t('التقرير المعتمد', 'Certified report');
  String get certifyReport => _t('اعتماد التقرير', 'Certify report');
  String get reportClosed => _t('نافذة التقرير مغلقة', 'Report window is closed');
  String get reportOpensIn => _t('تفتح خلال', 'Opens in');
  String get reportWindowInfo => _t(
      'نافذة التقرير من 8:00 مساءً حتى 3:00 فجرًا بتوقيتك.',
      'Report window is 8:00 PM to 3:00 AM in your local time.');
  String get reviewAnswers => _t('راجع إجاباتك', 'Review your answers');
  String get finalTotal => _t('المجموع النهائي', 'Final total');
  String get reportCertified => _t('تم اعتماد التقرير', 'Report certified');
  String get reportLocked => _t('التقرير مقفل (تم استخدام التعديل الوحيد)', 'Report locked (single edit used)');
  String get reportSlow => _t(
      'تعذّر إتمام الاعتماد — تحقّق من اتصالك ثم أعد المحاولة.',
      'Certification timed out — check your connection and try again.');
  String get editReport => _t('تعديل التقرير', 'Edit report');
  String get oneEditLeft => _t('يمكنك التعديل مرة واحدة فقط', 'You can edit once only');
  String get yes => _t('نعم', 'Yes');
  String get no => _t('لا', 'No');
  String get next => _t('التالي', 'Next');
  String get back => _t('السابق', 'Back');

  // Conflicts
  String get conflictsTitle => _t('تعارض مع سجل اليوم', 'Conflicts with today\'s log');
  String get conflictsBody => _t(
      'بعض الإجابات تختلف عن سجل عاداتك. اختر الإجابة الصحيحة لكل عادة.',
      'Some answers differ from your habit log. Choose the correct answer for each.');
  String get keepReportAnswer => _t('اعتمد إجابة التقرير', 'Keep report answer');
  String get useLogAnswer => _t('استخدم إجابة السجل', 'Use habit log answer');
  String get resolveAllConflicts => _t('حلّ كل التعارضات للمتابعة', 'Resolve all conflicts to continue');

  // Stats
  String get statistics => _t('الإحصائيات', 'Statistics');
  String get perHabit => _t('حسب العادة', 'Per habit');
  String get general => _t('عام', 'General');
  String get lastWeek => _t('آخر أسبوع', 'Last week');
  String get lastMonth => _t('آخر شهر', 'Last month');
  String get last3Months => _t('آخر 3 أشهر', 'Last 3 months');
  String get allTime => _t('كل الوقت', 'All time');
  String get completionRate => _t('نسبة الإنجاز', 'Completion %');
  String get currentStreak => _t('السلسلة الحالية', 'Current streak');
  String get longestStreak => _t('أطول سلسلة', 'Longest streak');
  String get dailyAverage => _t('المعدل اليومي', 'Daily average');
  String get bestDay => _t('أفضل يوم', 'Best day');
  String get reportScores => _t('نتائج التقارير', 'Report scores');
  String get heatmap => _t('خريطة الأيام', 'Calendar heatmap');
  String get days => _t('يوم', 'days');
  String get noData => _t('لا توجد بيانات كافية بعد', 'Not enough data yet');

  // Championships
  String get championships => _t('البطولات', 'Championships');
  String championshipTitle(int month, int year) =>
      _t('بطولة شهر $month — $year', 'Championship $month/$year');
  String get monthTotal => _t('مجموع الشهر', 'Month total');
  String get pastChampionships => _t('البطولات السابقة', 'Past championships');
  String get top10 => _t('أفضل 10', 'Top 10');
  String get commitmentDoc => _t('وثيقة الالتزام', 'Commitment document');
  String get commitmentCardSubtitle =>
      _t('عهدك الشخصي — خاص بك وحدك', 'Your personal pledge — private to you');
  String get commitmentEmpty =>
      _t('لم تكتب وثيقة التزامك بعد', "You haven't written your commitment yet");
  String get writeCommitment => _t('اكتب وثيقتك', 'Write your commitment');
  String get commitmentHint => _t('اكتب التزامك هنا…', 'Write your commitment here…');
  String get exportPdf => _t('تصدير PDF', 'Export PDF');
  String writtenOnLabel(String d) => _t('حُرّرت في $d', 'Written on $d');
  String editedOnLabel(String d) => _t('آخر تعديل $d', 'Edited $d');
  String get noStandings => _t('لا نتائج لهذا الشهر بعد', 'No standings this month yet');

  // Leaderboard
  String get leaderboard => _t('المتصدرون', 'Leaderboard');
  String get thisMonth => _t('هذا الشهر', 'This month');
  String get totalPointsLabel => _t('مجموع النقاط', 'Total points');
  String get lastReport => _t('آخر تقرير', 'Last report');
  String get streak => _t('السلسلة', 'Streak');
  String get you => _t('أنت', 'You');
  String get noParticipants => _t('لا يوجد متصدرون بعد', 'No participants yet');

  // Qadaa (missed prayers)
  String get qadaa => _t('قضاء الصلاة', 'Prayer Qadaa');
  String get qadaaList => _t('قائمة القضاء', 'Qadaa list');
  String get pending => _t('المتبقّية', 'Pending');
  String get qadaaHistory => _t('السجل', 'History');
  String get markMadeUp => _t('قضيتها', 'Made up');
  String get noPendingQadaa => _t('لا صلوات فائتة 🎉', 'No missed prayers 🎉');
  String get noQadaaHistory => _t('لا يوجد سجل قضاء بعد', 'No qadaa history yet');
  String missedOn(String d) => _t('فات يوم $d', 'Missed on $d');
  String madeUpOn(String d) => _t('قُضيت يوم $d', 'Made up on $d');
  String get undo => _t('تراجع', 'Undo');
  String get qadaaNote => _t(
      'القضاء تتبّع شخصي فقط ولا يؤثّر على النقاط أو المتصدرين.',
      'Qadaa is personal tracking only — it does not affect points or the leaderboard.');
  String times(int n) => _t('×$n', '×$n');

  // Chat
  String get chat => _t('المحادثة', 'Chat');
  String get chatHint => _t('اكتب رسالة…', 'Type a message…');
  String get chatEmpty => _t('لا رسائل بعد — كن أول من يكتب!', 'No messages yet — say hi!');
  String get loadMore => _t('تحميل المزيد', 'Load more');
  String get send => _t('إرسال', 'Send');

  // Settings
  String get settings => _t('الإعدادات', 'Settings');
  String get appearance => _t('المظهر', 'Appearance');
  String get themeSystem => _t('حسب النظام', 'System');
  String get themeLight => _t('فاتح', 'Light');
  String get themeDark => _t('داكن', 'Dark');
  String get language => _t('اللغة', 'Language');
  String get arabic => _t('العربية', 'Arabic');
  String get english => _t('الإنجليزية', 'English');
  String get notifications => _t('الإشعارات', 'Notifications');
  String get account => _t('الحساب', 'Account');
  String get exportData => _t('تصدير بياناتي', 'Export my data');
  String get exportSubtitle => _t(
      'ملف Excel بكل عاداتك وسجلّك وتقاريرك والقضاء',
      'An Excel file with all your habits, logs, reports and qadaa');
  String get exporting => _t('جارٍ تجهيز الملف…', 'Preparing your file…');
  String get exportReady => _t('تم تجهيز الملف', 'File ready');
  String get exportShareText => _t('بيانات تطبيق البطولة', 'My Al-Butula data');
  String get exportError => _t('تعذّر تصدير البيانات', 'Could not export data');

  // Update gate
  String get updateTitle => _t('يتوفّر تحديث', 'Update available');
  String get updateBody =>
      _t('إصدار أحدث من التطبيق متوفّر.', 'A newer version of the app is available.');
  String get updateRequiredBody => _t(
      'يجب تحديث التطبيق للمتابعة.', 'You must update the app to continue.');
  String get updateNow => _t('تحميل التحديث', 'Download update');
  String get later => _t('لاحقًا', 'Later');

  // Generic
  String get loading => _t('جارٍ التحميل…', 'Loading…');
  String get error => _t('حدث خطأ', 'Something went wrong');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get warning => _t('تنبيه', 'Warning');
  String get done => _t('تم', 'Done');
  String get requiredField => _t('حقل مطلوب', 'Required');
  String get emptyName => _t('أدخل الاسم', 'Enter a name');
}

const arStrings = AppStrings(isArabic: true);
const enStrings = AppStrings(isArabic: false);
