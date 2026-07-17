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
