# Al-Butula (البطولة) 🏆

A group habit-tracking app with a custom points system, a certified daily report,
and a live monthly championship. Built with **Flutter/Dart**, running on **Android
and iOS** from one codebase. The app UI itself is Arabic-first (RTL) with English
support.

---

## Features

- **Accounts**: email/password sign-up; timezone chosen on first login.
- **Habit builder**: each user builds their own table from scratch (name,
  emoji/icon, points, type: daily/weekly/monthly).
- **The 100-point rule**: daily habit points must total exactly 100 (live bar +
  auto-distribute button).
- **Daily logging**: yes/no per habit (binary; default No), the five prayers as
  five separate items, instant save, and a calendar for editing past days.
- **App day boundary at 3:00 AM**: the app-day runs 3 AM → 3 AM local time; this
  applies to the today screen, logs, score, reports, stats, streaks, and qadaa.
- **Certified report**: window 8:00 PM → 3:00 AM (user's timezone) with a
  countdown, conflict detection against the day's log, and one allowed edit.
- **Notifications**: report reminders at 8 PM + 10 PM, plus optional per-habit
  reminders (all local, work offline).
- **Statistics**: per-habit charts + general stats and a monthly heatmap.
- **Championships**: monthly standings (current month + a top-10 archive of past
  months), computed from certified reports.
- **Prayer Qadaa**: missed prayers are tracked automatically at day end and can
  be marked as made up (fully private).
- **Group chat**: one shared realtime room for all users (no push notifications).
- **Export my data**: an Excel file with four sheets (habits, daily logs,
  certified reports, qadaa).
- **Commitment document**: a private personal pledge with a formal PDF export.

---

## Over-the-air updates (Shorebird)

The app is configured for **Shorebird code push** to ship Dart-level updates
without redistributing an APK (`shorebird.yaml` is present; `app_id` is created).

```bash
shorebird login          # once

# Create a new patchable release (this is the APK you send to friends)
shorebird release android --artifact apk
# Output: build/app/outputs/flutter-apk/app-release.apk

# Push a Dart-only update to users on the latest release — no new APK
shorebird patch android
```

**What can ship as a patch?** Any Dart code change (logic, UI, text, fixes). It
applies automatically on app launch (auto_update).

**What needs a full new APK?** Native changes: adding/updating plugins with
native code, permission or Gradle/Manifest changes, bumping the Flutter version,
or changing the app icon/name. In those cases run
`shorebird release android --artifact apk` and distribute the new APK.

### In-app version gate (fallback)
For full-APK updates, on startup the app reads `app_config/version` from Firestore:

```
app_config/version: { latestBuild: <int>, apkUrl: "<download url>", required: <bool> }
```

If the installed build is older than `latestBuild`, an Arabic dialog with a
download link appears (dismissible unless `required: true`). Edit this document
by hand in the Firebase console when you publish a new APK. (Rule: read-only for
signed-in users.)

---

## Requirements

- Flutter 3.44+ and Dart 3.12+
- **JDK 17** (required to build Android). If it isn't configured:
  ```bash
  flutter config --jdk-dir "$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
  ```
- Android SDK (platform-tools + android-36 + build-tools; minSdk 23+)
- To build iOS: a Mac with full **Xcode** and **CocoaPods**

---

## Firebase setup

The app is linked to the existing Firebase project **butula**
(`project_id: butula-bcf9d`) and uses **Cloud Firestore + Auth only**.

Both config files are already in place:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Steps in the Firebase console:

1. Enable **Authentication → Sign-in method → Email/Password**.
2. Enable **Cloud Firestore** (Native mode).
3. Deploy the security rules from `firestore.rules`:
   ```bash
   firebase deploy --only firestore:rules
   ```
   Chat, championships, and the version gate will NOT work until this runs.

> Note: the app never uses Realtime Database — Cloud Firestore only.

### Firestore structure

```
users/{uid}                      { name, email, timezone, createdAt, chatLastReadAt, lastSettledAppDay }
users/{uid}/habits/{habitId}     { name, emoji, iconCodePoint, points, type, schedule,
                                   reminderEnabled, reminderTime, isPrivate, order, subItems, deleted }
users/{uid}/logs/{YYYY-MM-DD}    { <habitKey>: true/false, ..., editedLater }
users/{uid}/reports/{YYYY-MM-DD} { answers, totalPoints, submittedAt, editCount }
users/{uid}/qadaa/{autoId}       { prayerKey, missedDate, madeUpDate }
users/{uid}/commitment/main      { text, createdAt, updatedAt }
championships/{YYYY-MM}           { month }                       // marker
championships/{YYYY-MM}/entries/{uid} { name, points, streak }
chat/{autoId}                    { senderUid, senderName, text, sentAt }
app_config/version               { latestBuild, apkUrl, required } // read-only
```

Private items and the commitment document live under `users/{uid}` and never
leave the user's own subtree.

---

## Build & run

```bash
flutter pub get
flutter analyze
flutter test
flutter run

# Release APK for direct Android install
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Verify the iOS code compiles (no signing needed)
flutter build ios --no-codesign
```

Prefer the **Shorebird** release command above for the APK you actually
distribute, so future Dart fixes can be patched over the air.

### App icon
Launcher icons are generated from `app_icon.png` (1024×1024) via
`flutter_launcher_icons` (Android adaptive icon with a `#1a472a` background +
iOS icon set). To regenerate: `dart run flutter_launcher_icons`.

---

## What's left for iOS distribution later

The code is fully iOS-ready (bundle id `com.yousef.butula`, notification
permissions, Podfile for iOS 13+, generated icon set). When you have a paid
Apple Developer account:

1. Open `ios/Runner.xcworkspace` in Xcode on a Mac.
2. Under **Signing & Capabilities**, pick your team.
3. Run once:
   ```bash
   cd ios && pod install && cd ..
   flutter build ios --release
   ```
4. Create the app in **App Store Connect** and upload via **TestFlight**.

---

## Project structure

```
lib/
  main.dart                 # Firebase + notifications init, app bootstrap
  app.dart                  # MaterialApp + theme + RTL
  firebase_options.dart     # Firebase config for Android & iOS
  core/                     # theme, strings (Arabic/English), utils, Riverpod providers
  models/                   # AppUser, Habit, DailyLog, DailyReport, QadaaEntry,
                            #   ChampionshipEntry, ChatMessage, Commitment, AppVersionConfig
  services/                 # Auth, Firestore, Notifications
  features/
    auth/                   # login, sign-up, timezone
    habits/                 # habit builder + 100-point rule + pickers
    logging/                # today (with date bar) + calendar + past-day editing
    report/                 # certified report + conflict detection
    stats/                  # charts and statistics
    championships/          # monthly championships + archive
    commitment/             # private commitment document + PDF
    chat/                   # group chat
    qadaa/                  # missed-prayer tracking
    update/                 # in-app version gate
    settings/               # settings + data export
    shell/                  # routing + bottom navigation
```

## State management

Riverpod (`flutter_riverpod`) throughout, with live Firestore listeners and a
local offline cache (Firestore offline persistence is enabled by default on
mobile).
