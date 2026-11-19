# Gharcha — the complete reference

Single source of truth for the product, the engineering handoff and the working context. Updated with every release zip.

## 1. What Gharcha is
Gharcha (ghar + kharcha: the home's expenses) is the Flutter rewrite of HomeQuest: a gamified household-expense manager for Android and iOS, built for Harshil (GitHub `HarshilBabariya/Kharchili`; the repo kept the app's previous working name). Members of one household log spending on one phone, split it in groups, keep budgets and earn points that unlock themes, avatar looks and features. Everything is local-first; the app has no server, no account and no ads.

- App name: **Gharcha** · app id / bundle id: `app.gharcha` · version `1.9.1+20`.
- It is a new app with its own id, so it installs beside HomeQuest. Data moves across by CSV: HomeQuest → Me → Your data → export, Gharcha → Me → Your data → Import CSV.
- Names: 1.0.x shipped as Kharchili (`app.kharchili`); 1.1.0 renamed it to Gharcha with a new id, so it installs as a separate app from a 1.0.x test build (move data with CSV export / import). Name check (Nov 2026): "Chillar" and "GharKharch" are taken by other expense apps; no app named Gharcha turned up in search. Do a store-console and trademark search before the first upload, because the app id cannot change afterwards.

## 2. Working agreements (project memory)
- Deliverable is an installable build, not code: each release is a zip to push to `main`; GitHub Actions builds it and publishes the website with that build on it.
- **Nothing in this project has been compiled on the authoring side.** There is no Flutter SDK or network there, so every release is statically reviewed and the first real compile is the Actions run. Expect to send the Actions log back for fixes after a large change such as this rewrite.
- Follow the coding standard and structure already in the project; no dead code, unused files or duplicated code; minimal comments.
- Every handover updates this document and the README in the same pass.
- Fixes are verified in a fresh review pass before a zip is handed over.

## 3. Features in 1.9.1
### Look, feel and flows (new in the rewrite)
- Icon: a white house holding a red rupee sign, with a saffron dot, on a red gradient; adaptive, legacy and themed (monochrome) Android icons, the iOS icon, the notification icon and both splash screens are pre-rendered into `platform/` by `tool/make_brand.py`. The Android 12+ splash shows the mark, then the opening moment plays on the brand red: the house rises, three gold coins drop into it (it bounces with each), the rupee writes itself, the saffron dot pops and the Gharcha wordmark and tagline slide in. It is the app's own story (money coming home); the earlier letter-with-orbiting-dots opening was too close to the reference app and is gone.
- Illustrated art instead of emoji: 33 badge medals (bronze, silver or gold rim by difficulty, one to three rank stars, an emblem per badge) and 24 sticker icons (groups, home services, empty screens, shop, gold, forecast). They are drawn as SVG and rendered to PNG by `tool/make_art.py` into `assets/art/`; the app shows them with `Medal` and `Sticker` (`lib/ui/glyphs.dart`). Locked medals are greyed behind a padlock with a progress ring. Points are a gold coin (`Coin`); categories and rows use glossy gradient tiles (`IconTile`).
- Docked full-width tab bar with four tabs and a raised glowing centre **+**; tab pages have no back button, pushed pages do.
- Every tappable surface shrinks under the finger and springs back, with haptics; screens build in with staggered slide-and-fade; numbers count up; rings, bars, area charts and donuts animate in and are tappable.
- Forms: labels sit above their fields (`KField`), two-to-four way choices are sliding segments (`Segmented`), sheets and pinned buttons stay clear of the system navigation bar, and a button ignores taps while its save is running (`KButton`), so nothing is saved or deleted twice.
- Add transaction: voice banner with a pulsing mic, Expense / Credit segments, a large amount with the currency symbol at the same weight and a money keypad that stays open, Yesterday / Today / Tomorrow chips, Paid by chips, four payment-mode tiles, group split (equal or custom) and a note. Saving floods the screen with the accent colour and a tick springs in, then a points toast with the coin floats up on Home.
- Celebrations for level-ups, badges, streak milestones and festivals are a card over looping confetti (or the festival's own particle show): the badge's medal, the flame or the dressed avatar on rotating rays, with the household sound and haptics. They wait until no sheet or pushed page is on top.
- Poppins for headings and numbers; soft colour glows behind every screen tinted by the active theme; light and dark for all 24 themes.

### Added in 1.9.1: more notifications
All are scheduled in `AppState._schedule` under the existing Reminders switch; the last three are skipped on the Quiet tone. Each opens its own screen through `Shell._followRoute` (new routes `services` and `savings`).
- **Lent and borrowed:** 10:00 on the return date and again three days later while unsettled (`NotificationIds.loan`).
- **Chit instalment:** 9:15 on the 1st of the month the next instalment falls in (`NotificationIds.chit`).
- **Home help pay:** 9:00 on the 1st of next month, naming the services whose current month is not marked paid.
- **Savings goals:** 10:00 on the 1st, with the total to put aside across goals that have a due month.
- **Month recap:** 9:30 on the 1st when the month has entries.
- **Dues digest:** Saturday 10:00, only when group dues or shop khata are pending.
- Limits: these are computed when the app last ran, so amounts can be stale if the app is not opened for weeks, and a service left unpaid from an earlier month gets no second notice.

### Added and fixed in 1.9.0 (device feedback on 1.8.x)
- **Quick access on Home:** a titled row of up to four app-icon style shortcuts under the hero card. "Edit" opens a sheet to pick them from ten screens (Bills, Shopping list, Savings goals, Lent and borrowed, Budgets, Insights, Papers, Accounts, Rewards, Voice entry). Stored as routes in `Settings.quickAccess`; taps go through `Notifier.open`, so `Shell._followRoute` is the one place that maps a route to a screen. The stat tiles below it now show at most four.
- **Share card looks:** every share preview offers five backgrounds (the theme's, Sunset, Emerald, Violet, Charcoal); tap a swatch or swipe the card. `CardLook` (an InheritedWidget in `screens/cards.dart`) carries the choice, and `ShareCard` and the weekly card paint `CardLook.of(context)`.
- **Loan reminder is a card:** Remind on a lent entry shares `LoanCard` (person, amount, lent date, return date) with the text as caption.
- **Goals, papers and loans can be edited:** tapping a card opens the same sheet used to add it. A paper's photo opens from its thumbnail. `Loan` and `Paper` fields are now mutable for this.
- **Back button:** on a tab other than Home, back goes to Home; on Home the first press shows "Press back again to exit" and a second press within two seconds closes the app (`PopScope` in `Shell`).
- **Keyboard:** a navigator observer in `main.dart` drops text focus whenever a screen or sheet closes, so the keyboard no longer reappears on Home.
- **Tabs:** `Segmented` gives each option width in proportion to its label, so a long label such as Accessories keeps the same text size as the others.
- Lent entries are green and borrowed ones orange, also when settled (faded). Day counts use plurals ("1 day overdue"). "Safe to spend today" is rounded to whole currency.

### Changed in 1.8.2
- **Restore accepts any file.** WhatsApp saves a shared backup as `DOC-…-WA0014.` with the `.json` ending stripped, and the picker only offered `.json` files, so the backup could not be chosen. The picker is now unfiltered; `Store.restore` already rejects anything that is not a Gharcha backup.

### Changed in 1.8.1
- **Payment capture is now in the Play Store build only.** In India, Play Protect refuses to install an APK from a browser, chat app or file manager when its manifest declares a notification listener ("App blocked to protect your device"), so the website APK no longer declares it and hides the Payment capture row.
  - `tool/patch_platforms.py --capture` adds the `<service>`; CI runs it only before `flutter build appbundle --dart-define=CAPTURE=true`.
  - `captureBuild` (`core/capture.dart`) gates the Me row and `AppState.syncCaptures`.
  - A local APK with capture: `python3 tool/patch_platforms.py --capture && flutter build apk --dart-define=CAPTURE=true`, installed with `adb install` (adb is not blocked).

### Added in 1.8.0
- **Home-screen widget (Android):** this month's spending, then "Safe to spend today" (or today's spending without a budget), with Add and Voice buttons. Tapping the card opens the app. Light and dark follow the phone.
  - Native side: `platform/android/kotlin/SpendWidget.kt`, `res/layout/spend_widget.xml`, `res/xml/spend_widget_info.xml`, `res/values*/widget_colors.xml`; `tool/patch_platforms.py` copies every file in `platform/android/kotlin` and adds the `<receiver>`.
  - Data: `AppState._refreshWidget` writes three ready-to-show lines through `Store.saveWidget` and broadcasts `app.gharcha.WIDGET_REFRESH` (via android_intent_plus); it runs at load and with the debounced notification sync. The widget also redraws itself every 30 minutes from the saved lines.
  - Buttons reuse the launcher-shortcut route: the intent carries the extra the quick_actions plugin reads (`SpendWidget.SHORTCUT`), so `Notifier.open` handles them. If a quick_actions update renames that extra, the buttons would only open the app.
  - The widget shows amounts on the home screen even when the app lock is on; it is only there if the user adds it.
- **8 new themes:** Mango, Mint, Lavender, Coffee, Peacock, Sunset, Rose gold, Ink (220–550 points).
- **Avatar:** 8 outfits (Tracksuit, Raincoat, Pathani, Anarkali, Bandhgala, Gown, Tuxedo, Pilot), 4 hairstyles (Top knot, Pigtails, Undercut, Long curls), 6 accessories (Tilak, Scarf, Bandana, Round glasses, Flower crown, Tiara). Outfits reuse the existing cuts with new colours; hair and accessories are new drawing in `ui/avatar.dart`.

### Changed in 1.7.1
- Build fix: `screens/shell.dart` now imports `core/app_state.dart` (1.7.0 failed `flutter analyze` on `AppScope`).
- **Launcher shortcuts** (long-press the app icon): Add transaction, Voice entry, Bills, Shopping list, each with its own icon (`platform/android/res/drawable/shortcut_<route>.xml`; the route name is the icon name). Android shows at most four.
- **Export sheet:** one chip per month that has expenses plus "All expenses", a CSV / PDF switch and a single Export button (`_ExportSheet` in `screens/me.dart`).
- **Rewards tabs** read History / Badges / Shop so all three labels render at the same size.

### Added in 1.7.0
- **Quick picks on Add transaction:** under the title field, chips offer past expenses. With nothing typed they are the most repeated ones (used at least twice); while typing they are the titles containing the text. A tap fills title, amount, category, payment mode and account (`AppState.quickPicks`).
- **A shop keeps its category:** captured, pasted and spoken entries take the category last used for the same title (`AppState.categoryFor`) before falling back to keyword guessing.
- **Safe to spend today** tile on Home when a budget is set: what was left this morning spread over the remaining days, less today's spending (`AppState.safeToday`).
- **Bill calendar** on Reminders: this month as a grid with due days marked, the amount still to pay, and what recurring bills cost per month and per year. Bills also notify three days early (`NotificationIds.earlySlot`).
- **Savings goals** (Me → Household money): target, optional due month, progress, the monthly amount needed, Add money.
- **Month recap:** during the first five days of a month Home offers last month's recap as a share card (`MonthCard`): spent, entries, change, biggest category, saved.
- **Shopping list** (Me → Household): add and tick items; "Log ticked items" opens Add transaction as Groceries with the items in the note and clears them once saved.
- **Lent and borrowed** (Me → Household money): person, amount, optional return date, overdue marker, Remind (share sheet) and Settled.
- **Advances for home help:** a monthly service can record an advance; it is logged as an expense at once and taken off the amount due when the month is marked paid (`HomeService.advances`, `AppState.payAdvance`).
- **Warranties and papers** (Me → Household): name, expiry date, optional photo; sorted by expiry with days left, notified a week before and on the day.
- **Payment-spotted alert:** the Android listener posts a notification as soon as a payment-looking SMS arrives; tapping it opens the app, where Home shows the capture banner. Its text is English only because it comes from native code.
- **Search by amount** on Expenses.
- **Accounts** (Me → Household money): named accounts with a starting balance; an expense can be tagged with one and the balance follows (`Expense.accountId`, `AppState.balanceOf`).
- Shared plumbing: `AppState.put` / `drop` save and remove any simple record list (and make Undo a re-`put`); `askText` and `pickPhoto` live in `screens/common.dart`; `AddExpenseScreen` takes a `draft` and an `onSaved` callback instead of a capture.
- Not built: **scan a bill** (reading the total from a receipt photo). It needs an on-device text-recognition package that raises the iOS minimum version and adds native libraries, which is too large a risk to add without a device to test on.

### Added in 1.6.0
- **Payment capture (Android):** with notification access granted, payments in bank and UPI SMS alerts appear under Me → Household money → Payment capture and as a banner on Home, each with Add (opens Add transaction filled in) or Dismiss. How it works:
  - `platform/android/kotlin/PaymentListener.kt` (copied next to `MainActivity.kt` by `tool/patch_platforms.py`, which also adds the `<service>` entry) is a `NotificationListenerService`. For notifications from SMS apps whose text contains a currency amount it appends `{sender, text, at}` to a JSON array in the `FlutterSharedPreferences` file (`flutter.capture_queue`) and records whether it is connected (`flutter.capture_connected`). No Flutter engine runs in the background.
  - On start and on every resume `AppState.syncCaptures` drains that queue (`Store.takeCaptured`), runs each message through `PaymentParser` (`core/capture.dart`, a port of HomeQuest's parser: skips OTPs, requests, failures, promotions; negative amount for money received) and stores what passes as `Capture` docs, skipping a repeat of the same amount within ten minutes.
  - `android_intent_plus` opens the system notification-access screen.

### Added in 1.5.0
- **Full-body avatars:** `AvatarView(full: true)` draws the whole standing figure (100 x 190 canvas in `_paintFull`): legs, shoes, arms, a full-length outfit per cut (tee, collar, hoodie, jacket, long kurta over light trousers, saree / dress skirt, one-piece suit) under the portrait's own head, hair, beard, accessories and mood marks. Jump, spin, dance, wave and cheer animate the whole body. Used for the avatar studio preview, outfit tiles in the studio and the shop, and the festival celebration; small round portraits stay everywhere else.
- **Receipt photo** on an expense: camera or gallery through `image_picker`, stored as a JPEG in the app's documents folder with its file name on the expense (`Expense.photo`); tap to view, replace or remove. Photos are not inside the backup file.
- **Accessibility:** icon-only buttons announce a label (`RoundIcon` maps its icons to strings; the centre + is labelled), switches announce their state, tappable surfaces are marked as buttons, decorative stickers and medals are hidden from screen readers, and text follows the phone's font size up to 130%.
- **Unit tests** in `test/core_test.dart` for the split calculator, the payment-message and voice parsers, PIN hashing and CSV. CI runs `flutter test` after analysis; the step reports but does not block the build until it has passed once on CI.

### Added in 1.4.0
- **Designed share cards** (`screens/cards.dart`): a settle-up reminder (both avatars, amount, group, the payee's UPI ID), a group summary (total and every member's balance), an expense receipt and an earned-badge card, all on the shared `ShareCard` frame. `shareCard` in `screens/export.dart` previews any card and shares it as a PNG with a text caption; the weekly card uses the same path. Remind and the group share button now send a card through the share sheet instead of plain text.
- **Split by percent or by shares** next to Equally and Amounts (`SplitType.percent`, `SplitType.weights`). Shares are still stored as amounts; the type records how they were entered so the form reopens the same way.
- **Across all groups:** the Groups tab opens with who owes you and whom you owe, summed over every group's settle-up plan (`AppState.myDues`).
- **Backup and restore** (Settings → Your data): Back up shares one JSON file holding every record and the settings; Restore replaces everything from such a file after a confirmation (`Store.dump` / `Store.restore`, ids preserved).
- **Performance:** badge progress is computed once per change instead of on every read; notification rescheduling is debounced to one pass two seconds after the last change. Lists were already built lazily by `ListView`, so no change was needed there.

### Added in 1.3.0
- **Edit a group:** the pencil on a group's page reopens the group sheet to rename it, change its sticker or its members. Saving re-splits the group's equal splits; custom splits are left alone.
- **No duplicate names:** the category, group and member sheets show "This name is already in use" under the field and keep Save disabled (`KField.error`).
- **Expense filters:** the filter button on Expenses opens date (all time, last 7 days, this month, last month), paid-by and payment-mode filters; an active-filter line shows the filtered net total with Clear. Categories moved off this header (they are in Me and in the category picker).
- **Swipe an expense row** (Expenses tab): left deletes with a 5-second Undo, right logs the same expense again for today.
- **Fingerprint or face unlock** (Settings → Security, for a member with a PIN): the phone's biometric check opens that member's profile from the PIN screen; the PIN always still works. Uses `local_auth` 2.3.0 through `core/biometrics.dart`. `tool/patch_platforms.py` switches `MainActivity` to `FlutterFragmentActivity`, gives the launch and normal themes an AppCompat parent, and adds the `USE_BIOMETRIC` permission and the iOS Face ID reason.
- **Me is short:** profile card, Household, Views, Household money, one Settings row and Log out. Appearance, notifications, security, data and help live on the new Settings screen (`SettingsScreen` in `screens/me.dart`).

### Added in 1.2.0
- **First expense in setup:** finishing onboarding opens Add transaction with a welcome card, so nobody lands on an empty Home. The budget in setup stays optional.
- **Shorter Home:** header, festival banner, spend card, stat tiles, streak, an Insights row, upcoming bills and recent transactions. The month curve, 7-day bars, category donut and who-paid moved to Insights; the weekly share card is the share button on Insights.
- **Insights are free for the current month** (hero stats, trend, categories). The shop unlock (300 points) adds Week / Year, paging back, change vs the previous period, payment modes and who paid.
- **Export is free:** CSV and PDF no longer need a shop unlock (`feature_export_csv` is gone from the catalog).
- **Notification tone** (Me → Notifications): Spicy (the roast pools), Mild (one plain line per kind, `plain_*` strings) or Quiet (plain wording and no comeback, weekly or streak-in-danger nudges). `AppState._copy` picks the wording.
- **Monthly income** (Budgets): with income set, Budgets shows spent-against-income and "Saved so far", and Home gets a "Saved this month" tile.
- **Repeat every month** switch on Add transaction: saving also creates a monthly auto-logging bill reminder for that day of the month.
- **Paste a payment message:** the "Paste a bank or UPI message" row under the voice banner on Add transaction (a labelled row since 1.5.1; the bare icon was not understood) reads the clipboard and fills amount, payee, payment mode, category and credit/debit (`MessageParser` in `core/parsers.dart`; falls back to the voice parser).
- **Settle up:** each settle-up card has Mark paid, plus **Pay by UPI** when you are the payer (opens the phone's UPI app through a `upi://pay` link using the payee's UPI ID, a new optional field on a member; INR households only) and **Remind** when you are owed (WhatsApp link, falling back to the share sheet).
- **Visible delete with undo:** groups have a delete button on their page (with confirmation, because their splits and settlements go too); gold items, chits and expenses delete from a visible button with a 5-second Undo bar. No delete is hidden behind a long-press any more.
- **App shortcuts:** long-press the launcher icon for Add transaction and Voice entry (`quick_actions`).
- **Privacy:** an in-app Privacy sheet (Me → More) and `website/public/privacy.html`, linked from the site footer, for the store listings.

### Carried over from HomeQuest, same behaviour
- Two-step setup (You, Money) with the step dots fixed in the header, after a welcome page with the language picker; you become the owner at Level 1 and get a daily 8:30 PM nudge.
- Family members with avatar, relation and optional 4-digit PIN (the unused mobile number was removed in 1.1.0) (weak PINs rejected, confirmed twice); member picker; App lock; log out / switch.
- Expenses with credits (stored negative, shown as +₹), four payment modes, search, category chips, day groups with subtotals, edit and delete.
- Calendar with compact day totals, green / red days against the average daily budget, month paging and a day's list.
- Custom categories: 26 icons, 40 colours and a custom hue; built-ins can be recoloured; deleting moves expenses to Other.
- Voice entry in English, Hindi and Gujarati with the same parser rules (amount, category words, payment words, credit words, the "note" marker).
- Groups: equal and custom splits, balances, minimal settle-up plan, Mark paid, share the summary.
- Budgets: monthly and per category, 80% / 100% alerts once per month per budget, plain-words forecast, +100 for a month under budget.
- Insights (shop unlock): Week / Month / Year with paging, hero stats, trend, category donut with change vs the previous period, payment-mode split, who paid.
- Reminders and bills: Once / Daily / Weekly / Monthly / Yearly, presets, optional amount and category, auto-log, a 30-day strip of what is due.
- Points, 10 levels, 33 badges with progress and how-to, current-streak rules and milestones, points history, shop with 15 themes shown as miniature screens, 18 outfits, 16 hair styles and 13 accessories shown on your own avatar, and 2 features.
- Avatar studio: gender, 10 moods or Auto, 6 skin tones, 7 hair colours, 5 face shapes, 6 beards, 7 actions, idle gestures; the avatar is drawn in code (shaded face, layered hair, outfit cuts, drawn mood marks, no emoji) and the studio keeps the preview pinned above Face / Hair / Outfits / Accessories tabs.
- Festivals: the same calendar for 2026–2030, nine packs, 3-day window, festive theme, banner with countdown and replay, first-open celebration, claim gifts (+50 ⭐, outfit and accessory), 9:00 greeting.
- Household money: kirana khata, milk / maid / services month grid with the bill maths and Mark paid, gold and chit funds.
- Data: CSV export and import with duplicate detection (same columns as HomeQuest), PDF export, weekly share card, Erase all.
- Three languages: every string ships in English, Hindi and Gujarati.

### Notifications (sassy by design)
- Every kind has its own Android channel and household sound: cooker whistle (nudges), doorbell (bills), debit ting (auto-logged), microwave (80%), card declined (over budget), piggy bank (badges), cash register (levels), ticking clock (streak in danger), stove (streak milestones), one per festival.
- Daily nudges never repeat the same line two days running: the next seven are each scheduled with a freshly picked title and line from the pools in the language files, and rescheduled whenever the app opens.
- New in Gharcha: a **comeback** nudge three days after the last time the app was opened ("Your ledger filed a missing report 🕵️") and a **Sunday 10 AM weekly roast** that opens Insights, both in three languages.
- Tapping a notification opens the right screen.

### Not in the Flutter app (deliberate, with the reason)
| HomeQuest feature | Status | Why |
|---|---|---|
| SMS / UPI auto-capture | Back since 1.6.0, Android only, Play Store build only since 1.8.1 | See "Added in 1.6.0". iOS has no way to read another app's notifications. HomeQuest shipped this only in its sideloaded "full" flavour and left it out of the Play "lite" flavour; Gharcha has one build, so check Google Play's notification-access and prominent-disclosure rules before a store upload and drop the `<service>` entry in `tool/patch_platforms.py` if it has to go. |
| Points packs paid by UPI | Removed | Both stores require their own billing for digital goods; a UPI top-up would get the app rejected. |
| Festival launcher icon and animated splash | Left out | Android activity-aliases and iOS alternate icons need native code per platform. |
| Hanging festival decor and the three "Lights" styles | Replaced | The banner now carries a looping particle show; the decor art was Compose-only. |
| Bills auto-log in the background | Changed | They are logged the next time the app opens, back-dated to the due day. |
| Share-to-Gharcha from a bank or UPI app | Replaced by paste | Receiving a share needs native code in both platform folders, which are generated at build time and cannot be compiled on the authoring side. Copy the message and tap paste instead. |
| Home-screen widget | Replaced by app shortcuts | A widget needs a native widget provider on Android and a WidgetKit extension on iOS. Long-press shortcuts cover quick add without native code; a real widget is a candidate once builds can be tested on a device loop. |
| Custom notification sounds on iOS | Android only | iOS needs the sounds bundled into the Xcode project. |
| PDF in Hindi / Gujarati script | Limited | The PDF is a plain Courier table written by the app itself (no PDF package); non-Latin text prints as ? and amounts use the currency code instead of ₹. |

## 4. Engineering handoff
### Stack and layout
Flutter (stable 3.38.x in CI, Dart 3.8+), Material 3. No state-management package: one `AppState` (`ChangeNotifier`) above `MaterialApp`, read with `AppScope.of(context)`.

```
lib/main.dart            boot, MaterialApp, opening animation
lib/core/                l10n, format (money, dates), models, catalogs (points, levels, rewards, badges, festivals),
                         store (sqflite + shared_preferences), app_state (all business rules), notifier (notifications, sounds), parsers (PIN, voice, payment messages, CSV), capture (payment-notification parser), biometrics
lib/ui/                  theme (16 palettes), widgets (design system), glyphs (stickers, medals, coin, theme preview), charts, avatar, effects (particles, flame, celebrations)
lib/screens/             shell (tabs), home, expenses + calendar, add_expense, categories, groups, budgets, insights, reminders,
                         rewards, me, family, avatar_studio, household (khata, services, savings), lists (shopping, loans, goals, papers, accounts), onboarding, lock, export, common
assets/l10n/{en,hi,gu}.json   strings, arrays and plurals; assets/sfx/*.mp3; assets/brand; assets/art (badges, icons); assets/fonts (Poppins, OFL)
platform/                launcher icons and splash for both platforms, raw notification sounds, notification icon, the sideload keystore
tool/                    bootstrap.sh, patch_platforms.py, check_strings.py, make_brand.py (icons, splash), make_art.py (medals, stickers; also writes website/public/art)
website/                 Vite + React + anime.js site
```

### Data
- `Store` keeps every entity as a JSON document in one sqflite table (`docs(id, kind, body)`), loaded into memory at start; `Settings` (preferences, points profile, unlocks, earned badges) is one JSON value in shared_preferences. Entities: member, category, expense, group, settlement, reminder, points, shop, khata, service, gold, chit.
- Adding a field means adding it to the model's `toJson` / `fromJson` with a default; no migration is needed.
- Expenses store the day as `yyyymmdd`, credits as negative amounts, group shares inline.

### Rules worth knowing
- Points, streak, level-ups, badge checks and budget alerts all run inside `AppState.saveExpense` → `_rewardLog` / `_checkBudgets` / `_afterChange`. Celebrations are queued on `AppState.celebrations` and shown by `CelebrationHost` in the shell.
- `AppState.syncNotifications` cancels and reschedules everything; it runs at start and after any change. After a change it is not awaited and it never throws (one pass at a time, a second call queues one more pass), so a notification failure can no longer stop a save from finishing. Save and delete handlers close their sheet first and write afterwards. Schedules are inexact (no exact-alarm permission, which Play restricts).
- `_dailyChecks` at start: last month's under-budget award, auto-logged bills, the festival celebration.
- Strings: `tr('key', [args])`, `trPick('array')`, `trPlural('key', n)`. `tool/check_strings.py` fails CI when a key is missing in any language or no longer used (`--prune` removes dead keys).
- Name clashes to avoid: do not import `package:flutter/foundation.dart` in a file that imports `core/models.dart` (both define `Category`).

### Native folders
`android/` and `ios/` are not in the repo. `tool/bootstrap.sh` runs `flutter create`, then `tool/patch_platforms.py` adds desugaring, signing, permissions (notifications, boot, microphone), the notification receivers, the app label, the raw sounds, the icons and splash from `platform/`, and the iOS usage strings. No icon or splash package is used: `flutter_launcher_icons` failed to compile in CI (its `image` dependency against the resolved `archive`), so the images are committed instead. To work locally: install Flutter, run `bash tool/bootstrap.sh`, then `flutter run`.

### CI (`.github/workflows/build.yml`)
One workflow, three jobs, on every push to `main`:
1. **android**: string check → bootstrap → `flutter analyze` → release APK (artifact `Gharcha-apk`); with the signing secrets set it also builds the Play bundle (artifact `Gharcha-play-bundle`).
2. **ios**: bootstrap → `flutter build ios --release --no-codesign` on macOS, to prove the iOS app compiles.
3. **site**: needs android; downloads that run's APK into `website/public/downloads/Gharcha.apk`, builds the site, checks the file is there and over 1 MB, deploys to GitHub Pages.

**Why the old download button failed:** the `deploy-site.yml` on `main` only built the website; it never copied an APK into it, so `downloads/HomeQuest-lite.apk` did not exist on the published site. The APK now travels inside the same workflow run and the deploy fails if it is missing. One-time repo setting: Settings → Pages → Source = GitHub Actions.

The sideload APK is signed with the committed `platform/android/sideload.keystore` (HomeQuest's old debug key, password `android`) so each build installs over the last one. It is public, so it must never sign a store build.

### Store release
**Google Play**
1. Create an upload key: `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Keep it safe; do not commit it.
2. Repo → Settings → Secrets → Actions: `ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`), `ANDROID_KEY_PASSWORD`.
3. Push; download `Gharcha-play-bundle` from the run and upload the `.aab` in Play Console (enrol in Play App Signing).
4. Listing needs: a privacy policy URL (the app collects nothing; the microphone is used only for voice entry), the Data safety form (no data collected or shared), content rating, screenshots. New personal developer accounts currently have to run a closed test (12 testers, 14 days) before production; check the Play Console for the current rule.
5. For each release raise `version:` in `pubspec.yaml` (the number after `+` must increase).

**App Store**
1. Needs an Apple Developer Program membership and a Mac with Xcode (or a signing-capable CI service).
2. Register the bundle id `app.gharcha` and create the app in App Store Connect.
3. On the Mac: `bash tool/bootstrap.sh`, open `ios/Runner.xcworkspace`, set the team under Signing, then `flutter build ipa --release` and upload with Transporter or Xcode.
4. App Privacy: "Data not collected". The microphone and speech-recognition reasons are already in Info.plist.

## 5. Release history
| Version | Date | Changes |
|---|---|---|
| 1.9.1 | 2026-11-19 | Notifications for loans, chit instalments, home help pay, savings goals, month recap and a weekly dues digest. |
| 1.9.0 | 2026-11-19 | Home quick access, five looks for share cards, loan reminder card, editable goals / papers / loans, back-twice-to-exit, keyboard and tab-size fixes. |
| 1.8.2 | 2026-11-19 | Restore picker no longer filters by file ending (a backup sent through WhatsApp loses `.json`). |
| 1.8.1 | 2026-11-19 | Website APK no longer declares the notification listener (Play Protect blocked its install); payment capture ships in the Play Store bundle only. |
| 1.8.0 | 2026-11-19 | Android home-screen widget; 8 themes; 8 outfits, 4 hairstyles and 6 accessories for the avatar. No new packages. |
| 1.7.1 | 2026-11-19 | Build fix (missing import in shell), launcher shortcuts with icons, export sheet with month chips and format switch, shorter Rewards tabs. |
| 1.7.0 | 2026-11-19 | Daily-use release: quick picks, remembered categories, safe-to-spend tile, bill calendar and early bill notice, savings goals, month recap card, shopping list, lent and borrowed, advances for home help, warranties and papers, payment-spotted alert, search by amount, accounts. No new packages. |
| 1.6.0 | 2026-11-19 | Payment capture from SMS notifications on Android, ported from HomeQuest (native listener, queue in shared preferences, capture inbox). New package: `android_intent_plus`. |
| 1.5.1 | 2026-11-19 | Fixes from device testing: the Undo message closes itself after five seconds (it no longer uses a `SnackBarAction`, which newer Flutter keeps on screen) and Undo is a solid yellow button on a dark bar; a swiped expense row's red / blue strip fills the row with no gap above or below; the selected category in the picker has a matching rounded outline and a tick instead of a circle around a square; paste is a labelled row with an explanation instead of an icon in the header. |
| 1.5.0 | 2026-11-19 | Full-body avatars; receipt photos (`image_picker`); screen-reader labels and capped text scaling; first unit tests and a non-blocking `flutter test` step in CI. |
| 1.4.0 | 2026-11-19 | Designed share cards (reminder, group, receipt, badge); percent and shares splits; cross-group dues on the Groups tab; backup and restore file; cached badge progress and debounced notification scheduling. No new packages. |
| 1.3.0 | 2026-11-19 | Edit group; duplicate-name checks; expense filters; swipe to delete / duplicate; fingerprint or face unlock (`local_auth`, native patches for FragmentActivity and AppCompat theme); Me split into a short page plus a Settings screen. |
| 1.2.1 | 2026-11-19 | Fixes from device testing of 1.2.0. Sheets that stayed open on Save and added a record per tap: every save / delete handler now closes the sheet before writing, and notification rescheduling runs in the background and cannot throw into a save. Tab pages (Home, Expenses, Groups, Me) cleared the tab bar by too little, hiding the last item; they now use the bar's real height. Long sheets (category, reminder, family member, service) keep Save / Delete pinned below a scrolling body (`KSheetForm`). Release builds no longer minify (`isMinifyEnabled = false`), because the notification plugin's stored schedules are known to break under code shrinking. |
| 1.2.0 | 2026-11-19 | First-expense step after setup; shorter Home; current-month Insights free and export free; notification tone (Spicy / Mild / Quiet); monthly income and savings; repeat-monthly expenses; paste a payment message; Pay by UPI and Remind on settle-up cards (member UPI ID); visible delete with undo; launcher shortcuts; privacy sheet and website privacy page. New packages: `url_launcher`, `quick_actions`. |
| 1.1.1 | 2026-11-19 | New opening animation built around the app (house, falling coins, rupee, tagline) replacing the letter-with-orbiting-dots one that mirrored the reference app. |
| 1.1.0 | 2026-11-19 | Renamed to **Gharcha** (`app.gharcha`) with a house-and-rupee icon. Redesign from device feedback on 1.0.3: illustrated medals and sticker icons replace every emoji used as an icon; redrawn avatar and a new avatar studio; docked full-width tab bar; themes as miniature previews; badge sheet and celebration card redesigned. Fixes: sheets and pinned buttons no longer sit under the system navigation bar; Save / Delete could fire repeatedly and the sheet stayed open when a celebration opened on top of it; back arrow on tab pages; onboarding dots moving between steps; amount field hiding its keypad; text overflow on the streak card, budgets and charts; extra space at the end of pages. Removed the unused member mobile number. Website: new logo, illustrated feature icons and badge strip. |
| 1.0.3 | 2026-11-18 | Build fix: the `pdf` package is removed because its `image` dependency did not compile against the resolved `archive`; `lib/screens/export.dart` now writes the PDF itself (Courier table, A4 landscape). The app has no dependency on `image` or `archive` any more. |
| 1.0.2 | 2026-11-18 | Build fix: the signing block in `android/app/build.gradle.kts` imports `java.util.Properties` (inside `android {}` the name `java` is Gradle's Java extension, so the qualified name did not resolve). |
| 1.0.1 | 2026-11-18 | Build fix: icons and splash are pre-rendered and copied by `tool/patch_platforms.py`; `flutter_launcher_icons` and `flutter_native_splash` removed after the launcher-icons tool failed to compile in CI. |
| 1.0.0 | 2026-11-18 | Gharcha: Flutter rewrite of HomeQuest 1.9.5 for Android and iOS under the new id `app.gharcha`; new lettermark icon and opening animation; redesigned navigation, add flow, charts and celebrations; comeback and weekly-roast notifications; one build instead of Full / Lite; SMS capture, UPI points packs and the festival launcher icon left out (see 3); website rebranded and its download fixed by building the APK and the site in one workflow. |
