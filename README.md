# البطولة (Al-Butula) 🏆

تطبيق تتبّع العادات الجماعي مع نظام نقاط مخصّص، وتقرير يومي معتمد، ولوحة متصدرين حيّة.
مبني بـ **Flutter/Dart** ويعمل على **Android و iOS** من نفس الكود.

---

## المزايا الرئيسية

- **حسابات**: تسجيل بالبريد وكلمة المرور، واختيار المنطقة الزمنية عند أول دخول.
- **بناء العادات**: كل مستخدم يبني جدوله من الصفر (اسم، إيموجي/أيقونة، نقاط، نوع يومي/أسبوعي/شهري).
- **قاعدة الـ100 نقطة**: مجموع نقاط العادات اليومية يجب أن يساوي 100 تمامًا (مع شريط مباشر وزر توزيع تلقائي).
- **التسجيل اليومي**: تفعيل/إلغاء لكل عادة، الصلوات الخمس كخمسة عناصر منفصلة، حفظ فوري، وتقويم لتعديل الأيام السابقة.
- **التقرير المعتمد**: نافذة من 8 مساءً حتى 7 صباحًا بتوقيت المستخدم، مع كشف التعارض مع سجل اليوم، وتعديل واحد مسموح.
- **الإشعارات**: تذكير التقرير 8م + 10م، وتذكيرات اختيارية لكل عادة (محلية، تعمل بدون إنترنت).
- **الإحصائيات**: رسوم بيانية لكل عادة + إحصائيات عامة وخريطة حرارية شهرية.
- **المتصدرون**: ترتيب حسب النقاط المعتمدة مع تحديث حيّ وفلترة (هذا الشهر / كل الوقت).
- **قضاء الصلاة**: تتبّع الصلوات الفائتة تلقائيًا وقضاؤها (شخصي بالكامل).
- **المحادثة**: غرفة دردشة جماعية واحدة لكل المستخدمين، فورية بدون إشعارات دفع.
- **تصدير بياناتي**: ملف Excel بأربع أوراق (العادات، السجل اليومي، التقارير، القضاء).

---

## قضاء الصلاة (Qadaa) والمحادثة (Chat)

### قضاء الصلاة 🕌
- عند تسجيل «لا» لأي من الصلوات الخمس (في التسجيل اليومي أو عبر التقرير المعتمد)،
  تُضاف تلك الصلاة تلقائيًا إلى **قائمة القضاء**.
- شاشة القضاء (من قسم الصلوات أو الإعدادات) تعرض الصلوات الفائتة مجمّعة حسب النوع
  مع العدد والتواريخ، وزر **«قضيتها»** لنقلها إلى سجل المقضيّة.
- إذا عدّلت لاحقًا يومًا سابقًا وغيّرت صلاة من «لا» إلى «نعم»، تُحذف تلقائيًا من
  القائمة (لكن لا تُحذف الصلوات التي سبق أن قُضيت).
- **لا يؤثّر القضاء على النقاط ولا على المتصدرين** — تتبّع شخصي خاص بك فقط.
- التخزين: `users/{uid}/qadaa/{autoId}` — ضمن نطاقك الخاص فقط (قواعد المالك).

### المحادثة الجماعية 💬
- غرفة واحدة مشتركة لكل المستخدمين، رسائل نصية فقط، فورية (Firestore realtime).
- تحميل أحدث 50 رسالة مع «تحميل المزيد» عند التمرير للأعلى.
- شارة **غير المقروء** على تبويب المحادثة (تعتمد على `chatLastReadAt` لكل مستخدم).
- بدون إشعارات دفع (لا Cloud Functions) — كل شيء داخل التطبيق مباشرة.
- التخزين: `chat/{autoId}` — يقرأها كل مستخدم مسجّل، ويكتب كلٌّ رسائله فقط باسم
  `uid` الخاص به، ولا تعديل/حذف للرسائل.

> **مهم:** أضفنا قواعد أمان جديدة لمجموعة `chat` في `firestore.rules`. أعد نشرها مرة
> واحدة عبر: `firebase deploy --only firestore:rules`. تُنشأ مجموعة `chat` تلقائيًا
> عند إرسال أول رسالة — لا حاجة لأي خطوة يدوية في وحدة تحكّم Firebase.

### تصدير بياناتي (Export) 📤
- من **الإعدادات → تصدير بياناتي** يُنشأ ملف Excel (`.xlsx`) بأربع أوراق منفصلة
  بالعربية: **العادات، السجل اليومي، التقارير المعتمدة، القضاء** — كلها بيانات
  المستخدم نفسه فقط، والتواريخ بصيغة YYYY-MM-DD.
- يُشارك الملف عبر `share_plus` (حفظ في الملفات، واتساب، بريد…) على أندرويد و iOS.
- مؤشّر تحميل أثناء التجهيز، ورسالة خطأ واضحة عند الفشل (بلا تعليق).
- حذف العادة أصبح **حذفًا ناعمًا** (تبقى في التصدير بوسم «محذوفة») للحفاظ على السجل.

---

## التحديثات عبر الهواء (Shorebird)

التطبيق مُهيّأ لـ **Shorebird code push** لإرسال تحديثات Dart دون توزيع APK جديد.
(`shorebird.yaml` موجود، و`app_id` مُنشأ.)

```bash
# تأكّد أنك مسجّل الدخول
shorebird login          # مرة واحدة

# إنشاء إصدار جديد قابل للترقيع (هذا هو الـ APK الذي ترسله لأصدقائك)
shorebird release android --artifact apk
# الناتج: build/app/outputs/apk/release/app-release.apk

# دفع تحديث (patch) للمستخدمين على آخر إصدار — بدون APK جديد
shorebird patch android
```

**ما الذي يمكن إرساله كـ patch؟** أي تغيير في كود Dart (منطق، واجهات، نصوص،
إصلاحات). يصل تلقائيًا عند فتح التطبيق (auto_update).

**ما الذي يتطلّب APK جديدًا (إصدار كامل)؟** تغييرات الجزء الأصلي: إضافة/تحديث
إضافات (plugins) فيها كود أصلي، تغيير الأذونات أو إعدادات Gradle/Manifest، رفع
إصدار Flutter، أو تغيير أيقونة/اسم التطبيق. في هذه الحالات:
`shorebird release android --artifact apk` ثم وزّع الـ APK الجديد.

### بوابة الإصدار داخل التطبيق (احتياطية)
لحالات الـ APK الكامل: عند بدء التشغيل يقرأ التطبيق `app_config/version` من
Firestore:

```
app_config/version: { latestBuild: <رقم>, apkUrl: "<رابط تحميل>", required: <bool> }
```

إذا كان الإصدار المثبّت أقدم من `latestBuild`، يظهر تنبيه عربي برابط التحميل
(قابل للتجاهل إلا إذا كان `required: true`). حرّر هذا المستند يدويًا من وحدة تحكّم
Firebase عند نشر APK جديد. (القاعدة: قراءة فقط للمستخدمين المسجّلين.)

---

## المتطلبات

- Flutter 3.44 أو أحدث، وDart 3.12+
- **JDK 17** (إلزامي لبناء Android). إن لم يكن مضبوطًا:
  ```bash
  flutter config --jdk-dir "$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
  ```
- Android SDK (platform-tools + android-36 + build-tools؛ minSdk = 23+)
- لبناء iOS: جهاز Mac مع **Xcode** كاملًا و **CocoaPods**

---

## ربط Firebase

المشروع مرتبط بمشروع Firebase الحالي **butula** (`project_id: butula-bcf9d`)، ويستخدم **Cloud Firestore + Auth فقط**.

ملفّا الإعداد موضوعان في أماكنهما الصحيحة مسبقًا:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

خطوات التفعيل في وحدة تحكّم Firebase:

1. فعّل **Authentication → Sign-in method → Email/Password**.
2. فعّل **Cloud Firestore** (Native mode).
3. انشر قواعد الأمان من الملف `firestore.rules`:
   ```bash
   firebase deploy --only firestore:rules
   ```
   أو انسخ محتوى `firestore.rules` يدويًا في Firestore → Rules.

> ملاحظة: التطبيق لا يستخدم Realtime Database إطلاقًا — Firestore فقط.

### بنية Firestore

```
users/{uid}                      { name, email, timezone, createdAt }
users/{uid}/habits/{habitId}     { name, emoji, iconCodePoint, points, type, schedule,
                                   reminderEnabled, reminderTime, isPrivate, order, subItems }
users/{uid}/logs/{YYYY-MM-DD}    { <habitKey>: true/false, ..., editedLater }
users/{uid}/reports/{YYYY-MM-DD} { answers, totalPoints, submittedAt, editCount }
leaderboard/{uid}                { name, totalPoints, lastReportPoints, lastReportDate,
                                   streak, monthPoints, monthKey }
```

العناصر الخاصة (بدون نقاط) تبقى داخل `users/{uid}/habits` ولا تخرج من نطاق المستخدم إطلاقًا.

---

## أوامر البناء والتشغيل

```bash
# تثبيت الحزم
flutter pub get

# فحص الكود
flutter analyze

# تشغيل الاختبارات
flutter test

# تشغيل على جهاز/محاكي
flutter run

# بناء APK للتثبيت المباشر على أندرويد
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk

# التحقق من أن كود iOS يُبنى (بدون توقيع)
flutter build ios --no-codesign
```

### تثبيت الـ APK على الهاتف

انسخ `build/app/outputs/flutter-apk/app-release.apk` إلى هاتفك وثبّته
(فعّل "التثبيت من مصادر غير معروفة" عند الطلب).

---

## ما يتبقّى لنشر iOS لاحقًا

الكود جاهز تمامًا لـ iOS (bundle id: `com.yousef.butula`، وأذونات الإشعارات، وPodfile مضبوط لـ iOS 13+).
لإكمال النشر عند توفّر حساب Apple Developer المدفوع:

1. افتح `ios/Runner.xcworkspace` في Xcode على جهاز Mac.
2. من **Signing & Capabilities** اختر فريق Apple Developer الخاص بك.
3. شغّل مرة واحدة:
   ```bash
   cd ios && pod install && cd ..
   flutter build ios --release
   ```
4. أنشئ التطبيق في **App Store Connect** وارفعه عبر **TestFlight**.

لا حاجة لعمل أيّ شيء من ذلك الآن — البنية جاهزة لإضافة ملفات التوقيع (provisioning profiles) عند الحاجة.

---

## بنية المشروع

```
lib/
  main.dart                 # تهيئة Firebase والإشعارات وتشغيل التطبيق
  app.dart                  # MaterialApp + الثيم + RTL
  firebase_options.dart     # إعداد Firebase لأندرويد و iOS
  core/                     # الثيم، النصوص (عربي/إنجليزي)، الأدوات، مزوّدات Riverpod
  models/                   # AppUser, Habit, DailyLog, DailyReport, LeaderboardEntry
  services/                 # Auth, Firestore, Notifications
  features/
    auth/                   # الدخول والتسجيل والمنطقة الزمنية
    habits/                 # بناء العادات + قاعدة الـ100 + المنتقيات
    logging/                # اليوم + التقويم + تعديل الأيام السابقة
    report/                 # التقرير المعتمد + كشف التعارض
    stats/                  # الرسوم البيانية والإحصائيات
    leaderboard/            # المتصدرون
    settings/               # الإعدادات
    shell/                  # التوجيه + شريط التنقّل السفلي
```

## إدارة الحالة

Riverpod (`flutter_riverpod`) لكل الحالة، مع مستمعي Firestore الحيّين وتخزين مؤقّت محلّي
يعمل دون اتصال (Firestore offline persistence مفعّل افتراضيًا على الجوال).
