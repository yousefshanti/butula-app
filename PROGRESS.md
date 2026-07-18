# PROGRESS — البطولة (Al-Butula)

## Build status
All 7 stages implemented. `flutter analyze` clean, 12 unit tests pass.
Release APK: `build/app/outputs/flutter-apk/app-release.apk`.
iOS: project fully configured but **cannot be built in the dev container** (no full
Xcode / CocoaPods). Build on a Mac with Xcode. See README.

---

## Investigation 2026-07-18 — "login hangs on the green splash screen"

### Root cause
Two compounding problems:

1. **Firestore security rules were never deployed.** `firestore.rules` existed
   locally and is correct, but there was no `firebase.json`/`.firebaserc` and
   `firebase deploy` was never run. The live `butula-bcf9d` DB used its default
   rules, which **deny all reads**. So reading `users/{uid}` after login returned
   `permission-denied`.

2. **The splash screen swallowed that error into an infinite spinner.**
   `root_gate.dart` mapped the `appUserProvider` (a `users/{uid}` `.snapshots()`
   stream) **error** state to `_Splash()`. On `permission-denied` the stream
   emitted an error → RootGate showed the splash forever, with no message,
   timeout, or retry.

Secondary: `AuthService.signUp` only caught `FirebaseAuthException`, not the
Firestore `FirebaseException`. With offline persistence the `users/{uid}` write
completed against the local cache (signup looked fine, Auth account appeared) but
the server write was silently rejected by the rules — so the doc likely never
existed on the server.

### Fix
- **`lib/features/shell/root_gate.dart`** — rewritten:
  - Signed-in flow split into `_SignedInGate`.
  - `appUserProvider` **error** → `_ErrorScreen` (clear message + Retry + Logout),
    with specific Arabic guidance when the error is `permission-denied`
    ("نشر قواعد الأمان"). Errors are `debugPrint`ed.
  - `appUserProvider` **data == null** (read OK but doc missing) → `_EnsureUserDoc`
    self-heals by creating the document, then the stream re-emits and routes on.
  - Loading splash shows a "taking longer than expected" hint after 12s so a
    stalled stream never looks like a permanent hang.
- **`lib/services/auth_service.dart`**:
  - `signUp` now wraps the Firestore write in `try/catch (FirebaseException)` so a
    rejected write no longer fails signup silently; it logs instead.
  - Added `ensureUserDoc()` — creates `users/{uid}` from the Auth user if missing
    (self-heals accounts created before rules were deployed). Rethrows so
    permission errors surface in the UI.
- **`firebase.json` + `.firebaserc`** added (project `butula-bcf9d`) so
  `firebase deploy --only firestore:rules` works out of the box.

### What the USER must still do (cannot be done from the dev container)
The dev container has no Firebase CLI / auth, so the rules must be deployed locally:

```bash
npm install -g firebase-tools     # if not installed
firebase login
cd <project root>
firebase deploy --only firestore:rules
```

Also confirm in the Firebase console: **Authentication → Email/Password enabled**,
and **Firestore Database created** (Native mode). After deploying rules, log in
again with the existing account — `ensureUserDoc()` will create the missing user
document, and routing proceeds to timezone setup → home.

### Verification done here
- `flutter analyze`: no issues.
- `flutter test`: 12/12 pass.
- Could NOT do a live device login (no emulator/device connected, and no account
  password), so the permission-denied path was verified by code inspection, not a
  captured console run.

---

## Feature A — Prayer Qadaa (قضاء الصلاة) — 2026-07-18

Tracks missed prayers for make-up. Personal-only: never affects leaderboard or
the daily 100.

- **Model** `lib/models/qadaa_entry.dart` — `{ prayerKey, missedDate, madeUpDate }`.
  `prayerKey` is the prayer name (e.g. الفجر) for grouping; pending while
  `madeUpDate == null`.
- **Firestore** `users/{uid}/qadaa/{autoId}` (already covered by the existing
  owner-only `users/{uid}/{document=**}` rule — no rules change needed).
- **Service** (`firestore_service.dart`): `qadaaStream`, idempotent
  `addMissedPrayer` (skips if any entry already exists for prayer+date),
  `removePendingMissedPrayer` (deletes only `madeUpDate == null` — never removes
  made-up entries), `reconcilePrayerQadaa`, `markQadaaMadeUp`, `undoQadaaMadeUp`.
- **Auto-add / sync triggers**:
  - Daily logging: `PrayerCheckCard` toggle calls `reconcilePrayerQadaa`
    (No → add missed, Yes → remove pending).
  - Certified report: `report_flow_screen` reconciles every prayer sub-item from
    the final certified answers after `certifyReport`.
- **Screen** `lib/features/qadaa/qadaa_screen.dart` — two tabs: Pending (grouped
  by prayer with ×count and dates, each with a "قضيتها" button) and History
  (made-up entries with dates + Undo).
- **Entry points**: Settings (with a pending-count badge via
  `pendingQadaaCountProvider`) and an icon on the prayers card header.
- Verified: `flutter analyze` clean, `flutter test` 13/13.

---

## Feature B — Group chat — 2026-07-18

Single shared chat room for all registered users. Text only, realtime, no push
notifications (no Cloud Functions).

- **Model** `lib/models/chat_message.dart` — `{ senderUid, senderName, text, sentAt }`.
- **Firestore** top-level `chat/{autoId}`, ordered by `sentAt`.
- **Service** (`firestore_service.dart`): `chatStream(limit)` (latest N,
  reversed to oldest-first for display), `latestChatStream()` (newest 1, for the
  badge), `sendChatMessage(text, name)` (writes `senderUid` = own uid +
  serverTimestamp), `markChatRead()` (writes `chatLastReadAt` on the user doc).
- **Pagination**: `chatLimitProvider` (StateProvider<int>, starts 50); scrolling
  near the top bumps it by 50 to load older messages.
- **Unread badge**: `hasUnreadChatProvider` compares the newest message's
  `sentAt` (from someone else) against `AppUser.chatLastReadAt`. Badge shown on
  the chat tab in the bottom nav. `chatLastReadAt` added to `AppUser`.
- **Screen** `lib/features/chat/chat_screen.dart` — RTL bubbles (own vs others
  aligned/coloured differently, sender name + time), composer, auto-scroll to
  bottom on new messages, marks read on open/new message.
- **Bottom nav** now has 6 tabs (اليوم / التقرير / الإحصائيات / المتصدرون /
  المحادثة / الإعدادات).
- **Security rules** (`firestore.rules`) — added `match /chat/{messageId}`:
  read if signed in; create only if `senderUid == auth.uid`; `update, delete` =
  false (messages immutable). **Must be redeployed:** `firebase deploy --only
  firestore:rules` (can't be done from the dev container — no Firebase CLI/auth).
  The `chat` collection auto-creates on the first message write.
- Verified: `flutter analyze` clean, `flutter test` 15/15.

> iOS: no code changes to the native iOS project; both new features are pure
> Dart. `flutter build ios --no-codesign` still cannot run in the dev container
> (no full Xcode), unchanged from before — build on a Mac with Xcode.

---

## Bug fix — certify spinner never resolves — 2026-07-18

### Root cause
`ReportFlowScreen._certify` had **no try/catch/finally and no timeout**. Order was:
`_submitting = true` → `certifyReport` (a plain `reports/{date}.set()` that persists
to the local cache immediately, **then** a `runTransaction` for the leaderboard) →
qadaa-reconcile loop of Firestore queries → notification cancel. If the leaderboard
transaction hung/threw (poor connectivity — transactions need the server) or any
later step threw, the exception escaped the async method, `_submitting` stayed
`true` forever, yet the report `.set()` had already written locally — so it showed
certified after navigating back and returning.

### Fix
- **`firestore_service.certifyReport`** — the report `.set()` is the critical await
  (local-first, fast). The streak + leaderboard transaction moved to
  `_pushLeaderboard`, called **best-effort** inside a `try` with a 12s `timeout`,
  and the prior-report read is bounded (8s, null fallback). So `certifyReport`
  always returns quickly regardless of connectivity; the leaderboard self-corrects
  on the next certify.
- **`report_flow_screen._certify`** — wrapped in try/catch with a 20s timeout on
  the critical write; captures `ScaffoldMessenger`/`Navigator` before the awaits
  (guarded by `mounted`); on success pops + shows a success SnackBar; on
  `TimeoutException` or error resets `_submitting` and shows a clear message
  (no more infinite spinner — same pattern as the login fix). Side effects (qadaa
  reconcile, 10PM-reminder cancel) are now `unawaited` + wrapped so they can never
  block or break the success path.
- Could not device-test the spinner live (no emulator/device); verified by tracing
  every code path (success pops; timeout/error reset the spinner) + analyze + tests.

---

## Tri-state habit logging + prayer windows — 2026-07-18

Distinguishes **not-yet-answered** from an explicit **No** so unanswered habits
don't silently count against the user.

- **`DailyLog`** — added `LogState { unanswered, done, notDone }` + `stateOf(key)` /
  `isAnswered(key)`. Storage is unchanged: an **absent** key = unanswered, a present
  bool = explicit answer. Scoring already only sums `true`, so unanswered = 0 (never
  a penalty), never treated as "No".
- **`FirestoreService.setLogState`** — writes true/false, or `FieldValue.delete()` to
  revert a key to genuine unanswered.
- **`TriStateCheck`** widget (core/widgets.dart) — neutral grey dash (unanswered) vs
  green check (done) vs red X (notDone); tapping cycles unanswered → done → notDone →
  unanswered. Used by Home habit tiles and each prayer sub-item.
- **Prayer windows** (`core/prayer_times.dart`) — `prayerWindowPassed(name, date, tz)`
  using **approximate** fixed local window-end hours (الفجر 6, الظهر 15, العصر 18,
  المغرب 20, العشاء 24). NOTE: these are rough approximations, not astronomically
  computed times (would need lat/long + a prayer-times lib). An unanswered prayer
  whose window has passed shows a "⌛ فات وقتها" hint on Home; qadaa is still only
  written on an explicit tap or at report time (never preemptively before the window).
- **Qadaa reconciliation** on the prayer control: notDone → add missed; done/unanswered
  → remove pending (so un-answering clears a mistaken entry). Made-up entries are never
  removed.
- **Report flow** — `_answers` is now `Map<String, bool?>`; a fresh report pre-selects
  from the log's explicit state and leaves unanswered items with **no pre-selection**
  (not defaulted to No). Any still-unanswered item resolves to No only at certification
  (the report window is always after all prayer windows). Confirm list shows a neutral
  icon for unanswered.
- Verified: `flutter analyze` clean, `flutter test` 17/17.

---

## Feature — Export my data (.xlsx) — 2026-07-18

Settings → "تصدير بياناتي" generates a real multi-sheet Excel workbook of the
user's OWN data and shares it via share_plus (Android + iOS).

- **Deps added**: `excel: ^4.0.6`, `share_plus: ^10.1.4`, `path_provider: ^2.1.5`
  (share_plus was NOT already present, contrary to the request's assumption).
  share_plus 10.1.4 uses the static `Share.shareXFiles(...)` API (not the v11
  `SharePlus.instance`/`ShareParams`).
- **Soft-delete for habits** (needed for the "active or deleted" column):
  `Habit.deleted` flag added; `deleteHabit` now sets `deleted: true` (merge)
  instead of removing the doc; `habitsStream` filters deleted out everywhere;
  `allHabitsRaw()` returns them for export. NOTE: habits hard-deleted *before*
  this change are already gone and can't be recovered.
- **`lib/features/settings/data_export.dart`**:
  - `buildExportWorkbook(...)` — pure, unit-tested function building 4 sheets:
    العادات (name, emoji, points, type, private?, active/deleted),
    السجل اليومي (one row per answered habit entry per day: date, habit name,
    done yes/no, edited-later), التقارير المعتمدة (date, total, submitted-at,
    edited?), القضاء (prayer, missed date, made-up date or "لم تُقضَ بعد").
    All headers Arabic; dates YYYY-MM-DD. Removes the default 'Sheet1'.
  - `exportUserDataToXlsx(svc)` — parallel fetch via Dart-3 record `.wait`,
    builds workbook, writes to the temp dir, returns the `File`.
  - New service reads: `allHabitsRaw`, `allLogs`, `allReports`, `allQadaa`.
- **UI** (settings_screen): non-dismissible loading dialog while generating,
  60s timeout, then `Share.shareXFiles` with an iPad `sharePositionOrigin`; on
  error the dialog closes and a clear SnackBar shows (no infinite spinner).
- Verified: `flutter analyze` clean, `flutter test` 18/18 (incl. a workbook
  builder test asserting the 4 Arabic sheets + row counts). Could not device-test
  the share sheet (no device); logic + build verified.

---

## Batch 2026-07-18 (fixes then features)

### [1] Chat permission-denied
`firestore.rules` already covers `chat` correctly (authed read + create-own,
no edit/delete). The live project just never had the rules deployed. Extended the
same file with `championships` and `app_config` rules (for [6]/[8]) so one deploy
covers everything. **ACTION REQUIRED (user):** `firebase deploy --only firestore:rules`
— chat, championships, and the version gate will not work until this runs.

### [2] Reverted tri-state → binary logging
Removed `LogState`/`TriStateCheck`/`setLogState` and the prayer-window gating
(`core/prayer_times.dart` deleted). Habits default NO; tapping toggles YES/NO;
unchecked = 0. `PrayerCheckCard` back to binary checkboxes (flip to YES clears any
pending qadaa; missed prayers are now added at the 3AM settlement — see [4]).
Report flow back to `Map<String,bool>` (default from log), and no longer writes
qadaa (settlement owns that). analyze clean, 17/17 tests.

### [3] App day boundary at 3:00 AM
`core/date_utils.dart`: `appDayKeyOf(instant)` = `dateKey(instant - 3h)`.
`todayKey(loc)` now returns the app-day, so the boundary propagates everywhere
that already used it (today screen, logs, score, calendar cap, qadaa made-up date).
Report window is now 8:00 PM → 3:00 AM (`ReportWindow.now` opens at the app-day's
8 PM, open while `hour>=20 || hour<3`). Added `currentAppMonthKey(loc)`. Report
info string updated to "8 مساءً حتى 3 فجرًا". Notifications (8 PM + 10 PM) unchanged.
analyze clean, 19/19 tests (incl. boundary tests at 1:30/2:59/3:00 AM).

### [4] Automatic qadaa at day end (lazy settlement)
`FirestoreService.settleQadaa(habits, currentAppDay)` — runs on app open
(home_shell `_onStartup`, after awaiting the habit list). For every fully-ended
app-day since `lastSettledAppDay` (bounded to 60 days), any of the five prayers
still logged NO becomes a pending qadaa entry. Idempotent (2 reads + 1 batch;
dedups against existing entries), advances `lastSettledAppDay` on the user doc.
First run initialises the marker without back-filling. Flipping a prayer to YES
still removes its pending entry immediately (`PrayerCheckCard` →
`removePendingMissedPrayer`); made-up entries are never auto-removed. Settlement
is best-effort (retries next launch on error). analyze clean, 19/19 tests.

### [5] Date navigation bar on Today screen
`HomeScreen` is now stateful with `_selectedDate` (app-day). A subtle `_DateBar`
(prev/next chevrons + `dayLabel` e.g. "الجمعة ١٧ يوليو") sits under the app bar;
next is capped at today. Past days load that day's log, editable and flagged
edited-later (tiles get `isPast: true`). The calendar button is unchanged.
Added `shiftDayKey` + `dayLabel` (Arabic/English) to date_utils. 21/21 tests.

### [6] Championships page (monthly + archive)
"المتصدرون" → "البطولات". New cross-readable collection
`championships/{YYYY-MM}` (marker) + `championships/{YYYY-MM}/entries/{uid}`
`{ name, points, streak }`. On certify, `_pushLeaderboard` computes the user's
month total from their own reports (`_myMonthTotal`, folding in the fresh current
value/edits) and upserts their entry. `ChampionshipsScreen` shows the current
month standings (title "بطولة شهر M — YYYY", ranked, streak, current-user
highlight) + a "البطولات السابقة" archive: past-month `ExpansionTile`s showing
each month's top 10. A new month starts everyone from zero automatically (its
entries don't exist yet); no data is reset/deleted. Nav tab + icon updated
(emoji_events). Old `leaderboard_screen.dart` removed. Rules for `championships`
added in [1]'s file. analyze clean, 21/21 tests.
NOTE: standings aggregate only across users who have certified that month
(each writes their own entry) — correct for this friends group.

### [7] Commitment Document (وثيقة الالتزام) + PDF
Private `users/{uid}/commitment/main` `{ text, createdAt, updatedAt }` (covered by
the existing own-data rule). `commitmentProvider` + service `commitmentStream`/
`saveCommitment` (sets createdAt only on first write). `CommitmentScreen`: empty
state → editor; ornamental framed view (gold+green double border, Cairo, name +
written/edited dates) with an edit FAB; PDF export via `commitment_pdf.dart`
(`pdf` + `printing`, Amiri font via `PdfGoogleFonts`, RTL, same formal frame)
shared through `Printing.sharePdf`. Entry card added to the Championships page.
Deps added: `pdf`, `printing`, `package_info_plus`. analyze clean, 21/21 tests.
(PDF/share not device-tested here; the font fetch needs network on first use.)

### [8] Shorebird OTA + in-app version check
- **Shorebird**: `shorebird init` created `shorebird.yaml` (app_id
  d43a3891-dd0e-4eda-babb-8637629e4404) and added it to pubspec assets. Shorebird
  1.6.113 on Flutter 3.44.6 (matches the project). Release built with
  `shorebird release android --artifact apk`. Patch flow + "what needs a full
  APK" documented in the README. The distributable APK from Shorebird is the one
  to send to friends (Shorebird-enabled so future Dart patches apply OTA).
- **Version gate**: `app_config/version` `{ latestBuild, apkUrl, required }`
  (read-only rule). On startup (`checkForUpdate`, `home_shell`), compares the
  installed build (`package_info_plus`) to `latestBuild`; if older, shows an
  Arabic dialog with a download link (`url_launcher`), dismissible unless
  `required`. Best-effort — never blocks the app. Deps added: `url_launcher`.
  analyze clean, 22/22 tests (incl. version-config parsing).

## App icon + name — 2026-07-18
Generated launcher icons from `app_icon.png` (1024×1024) via
`flutter_launcher_icons` (^0.14 → 0.14.4): Android default + adaptive
(foreground = source, background `#1a472a` in `colors.xml`,
`mipmap-anydpi-v26/ic_launcher.xml`), iOS `AppIcon.appiconset` (21 sizes,
`remove_alpha_ios`). Display name was already "البطولة" on both platforms
(Android `android:label`, iOS `CFBundleDisplayName`); no `butula_flutter`
placeholder found anywhere. `CFBundleName` stays `butula` (internal only).
pubspec description already carries the Arabic tagline; no web/ metadata exists.
Bumped version to **1.0.1+2** (icon = native change, needs a new Shorebird
release, not a patch) and rebuilt the Shorebird release APK.
