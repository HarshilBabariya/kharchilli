# Gharcha — the complete reference

Single source of truth for the product, the engineering handoff and the working context. Updated with every release zip.

## 1. What Gharcha is
Gharcha (ghar + kharcha: the home's expenses) is the Flutter rewrite of HomeQuest: a gamified household-expense manager for Android and iOS, built for Harshil (GitHub `HarshilBabariya/Kharchili`; the repo kept the app's previous working name). Members of one household log spending on one phone, split it in groups, keep budgets and earn points that unlock themes, avatar looks and features. Everything is local-first; the app has no server, no account and no ads.

- App name: **Gharcha** · app id / bundle id: `app.gharcha` · version `1.1.0+5`.
- It is a new app with its own id, so it installs beside HomeQuest. Data moves across by CSV: HomeQuest → Me → Your data → export, Gharcha → Me → Your data → Import CSV.
- Names: 1.0.x shipped as Kharchili (`app.kharchili`); 1.1.0 renamed it to Gharcha with a new id, so it installs as a separate app from a 1.0.x test build (move data with CSV export / import). Name check (Nov 2026): "Chillar" and "GharKharch" are taken by other expense apps; no app named Gharcha turned up in search. Do a store-console and trademark search before the first upload, because the app id cannot change afterwards.

## 2. Working agreements (project memory)
- Deliverable is an installable build, not code: each release is a zip to push to `main`; GitHub Actions builds it and publishes the website with that build on it.
- **Nothing in this project has been compiled on the authoring side.** There is no Flutter SDK or network there, so every release is statically reviewed and the first real compile is the Actions run. Expect to send the Actions log back for fixes after a large change such as this rewrite.
- Follow the coding standard and structure already in the project; no dead code, unused files or duplicated code; minimal comments.
- Every handover updates this document and the README in the same pass.
- Fixes are verified in a fresh review pass before a zip is handed over.

## 3. Features in 1.1.0
### Look, feel and flows (new in the rewrite)
- Icon: a white house holding a red rupee sign, with a saffron dot, on a red gradient; adaptive, legacy and themed (monochrome) Android icons, the iOS icon, the notification icon and both splash screens are pre-rendered into `platform/` by `tool/make_brand.py`. The Android 12+ splash shows the mark, then the opening moment draws the house and rupee and brings in the Gharcha wordmark.
- Illustrated art instead of emoji: 33 badge medals (bronze, silver or gold rim by difficulty, one to three rank stars, an emblem per badge) and 24 sticker icons (groups, home services, empty screens, shop, gold, forecast). They are drawn as SVG and rendered to PNG by `tool/make_art.py` into `assets/art/`; the app shows them with `Medal` and `Sticker` (`lib/ui/glyphs.dart`). Locked medals are greyed behind a padlock with a progress ring. Points are a gold coin (`Coin`); categories and rows use glossy gradient tiles (`IconTile`).
- Docked full-width tab bar with four tabs and a raised glowing centre **+**; tab pages have no back button, pushed pages do.
- Every tappable surface shrinks under the finger and springs back, with haptics; screens build in with staggered slide-and-fade; numbers count up; rings, bars, area charts and donuts animate in and are tappable.
- Forms: labels sit above their fields (`KField`), two-to-four way choices are sliding segments (`Segmented`), sheets and pinned buttons stay clear of the system navigation bar, and a button ignores taps while its save is running (`KButton`), so nothing is saved or deleted twice.
- Add transaction: voice banner with a pulsing mic, Expense / Credit segments, a large amount with the currency symbol at the same weight and a money keypad that stays open, Yesterday / Today / Tomorrow chips, Paid by chips, four payment-mode tiles, group split (equal or custom) and a note. Saving floods the screen with the accent colour and a tick springs in, then a points toast with the coin floats up on Home.
- Celebrations for level-ups, badges, streak milestones and festivals are a card over looping confetti (or the festival's own particle show): the badge's medal, the flame or the dressed avatar on rotating rays, with the household sound and haptics. They wait until no sheet or pushed page is on top.
- Poppins for headings and numbers; soft colour glows behind every screen tinted by the active theme; light and dark for all 16 themes.

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
- Points, 10 levels, 33 badges with progress and how-to, current-streak rules and milestones, points history, shop with 7 themes shown as miniature screens, 18 outfits, 16 hair styles and 13 accessories shown on your own avatar, and 2 features.
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
| SMS / UPI auto-capture | Left out | Needs a notification-listener; Play restricts it and iOS has no equivalent. Voice entry covers the quick-log case. |
| Points packs paid by UPI | Removed | Both stores require their own billing for digital goods; a UPI top-up would get the app rejected. |
| Festival launcher icon and animated splash | Left out | Android activity-aliases and iOS alternate icons need native code per platform. |
| Hanging festival decor and the three "Lights" styles | Replaced | The banner now carries a looping particle show; the decor art was Compose-only. |
| Bills auto-log in the background | Changed | They are logged the next time the app opens, back-dated to the due day. |
| Custom notification sounds on iOS | Android only | iOS needs the sounds bundled into the Xcode project. |
| PDF in Hindi / Gujarati script | Limited | The PDF is a plain Courier table written by the app itself (no PDF package); non-Latin text prints as ? and amounts use the currency code instead of ₹. |

## 4. Engineering handoff
### Stack and layout
Flutter (stable 3.38.x in CI, Dart 3.8+), Material 3. No state-management package: one `AppState` (`ChangeNotifier`) above `MaterialApp`, read with `AppScope.of(context)`.

```
lib/main.dart            boot, MaterialApp, opening animation
lib/core/                l10n, format (money, dates), models, catalogs (points, levels, rewards, badges, festivals),
                         store (sqflite + shared_preferences), app_state (all business rules), notifier (notifications, sounds), parsers (PIN, voice, CSV)
lib/ui/                  theme (16 palettes), widgets (design system), glyphs (stickers, medals, coin, theme preview), charts, avatar, effects (particles, flame, celebrations)
lib/screens/             shell (tabs), home, expenses + calendar, add_expense, categories, groups, budgets, insights, reminders,
                         rewards, me, family, avatar_studio, household (khata, services, savings), onboarding, lock, export, common
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
- `AppState.syncNotifications` cancels and reschedules everything; it runs at start and after any change. Schedules are inexact (no exact-alarm permission, which Play restricts).
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
| 1.1.0 | 2026-11-19 | Renamed to **Gharcha** (`app.gharcha`) with a house-and-rupee icon. Redesign from device feedback on 1.0.3: illustrated medals and sticker icons replace every emoji used as an icon; redrawn avatar and a new avatar studio; docked full-width tab bar; themes as miniature previews; badge sheet and celebration card redesigned. Fixes: sheets and pinned buttons no longer sit under the system navigation bar; Save / Delete could fire repeatedly and the sheet stayed open when a celebration opened on top of it; back arrow on tab pages; onboarding dots moving between steps; amount field hiding its keypad; text overflow on the streak card, budgets and charts; extra space at the end of pages. Removed the unused member mobile number. Website: new logo, illustrated feature icons and badge strip. |
| 1.0.3 | 2026-11-18 | Build fix: the `pdf` package is removed because its `image` dependency did not compile against the resolved `archive`; `lib/screens/export.dart` now writes the PDF itself (Courier table, A4 landscape). The app has no dependency on `image` or `archive` any more. |
| 1.0.2 | 2026-11-18 | Build fix: the signing block in `android/app/build.gradle.kts` imports `java.util.Properties` (inside `android {}` the name `java` is Gradle's Java extension, so the qualified name did not resolve). |
| 1.0.1 | 2026-11-18 | Build fix: icons and splash are pre-rendered and copied by `tool/patch_platforms.py`; `flutter_launcher_icons` and `flutter_native_splash` removed after the launcher-icons tool failed to compile in CI. |
| 1.0.0 | 2026-11-18 | Gharcha: Flutter rewrite of HomeQuest 1.9.5 for Android and iOS under the new id `app.gharcha`; new lettermark icon and opening animation; redesigned navigation, add flow, charts and celebrations; comeback and weekly-roast notifications; one build instead of Full / Lite; SMS capture, UPI points packs and the festival launcher icon left out (see 3); website rebranded and its download fixed by building the APK and the site in one workflow. |
