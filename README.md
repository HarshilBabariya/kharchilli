# Gharcha

The home's expenses, with spice: log spends in seconds (by voice if you like), split them with the family, keep budgets and get lovingly roasted when you overspend. Points, streaks, badges, avatars and festival packs keep everyone logging. One Flutter codebase for Android and iOS; local-first, no account, no ads.

Gharcha is the rewrite of HomeQuest. Everything about the product, the code and the release process is in **[docs/GHARCHA.md](docs/GHARCHA.md)**.

## Get a build
Push to `main`. The **Build and publish** workflow builds the Android APK, proves the iOS app compiles, and publishes the website with that APK behind its download button. The APK is also on the run page as the `Gharcha-apk` artifact.

One-time setup: repo Settings → Pages → Source = **GitHub Actions**.

## Work on it locally
```
bash tool/bootstrap.sh   # flutter create + native settings, icons and splash
python3 tool/make_art.py # only after changing a badge or sticker drawing
flutter run
```

## Ship to the stores
Steps for Google Play (upload key and four repo secrets) and the App Store (Apple Developer account and a Mac) are in section 4 of the reference doc.

## Version history
| Version | Date | Notes |
|---|---|---|
| 1.10.2 | 2026-11-19 | Real share card styles, themed Undo, removable khata payments |
| 1.10.1 | 2026-11-19 | Second build artifact with payment capture |
| 1.10.0 | 2026-11-19 | Editing everywhere, goal history, quick tips, website download fix |
| 1.9.1 | 2026-11-19 | Notifications for loans, chits, home help, goals, recap, dues |
| 1.9.0 | 2026-11-19 | Quick access, share card looks, editable lists, back-to-exit |
| 1.8.2 | 2026-11-19 | Restore works with backups sent through WhatsApp |
| 1.8.1 | 2026-11-19 | Install fix: payment capture moved to the Play Store build |
| 1.8.0 | 2026-11-19 | Home-screen widget, 8 themes, 18 avatar items |
| 1.7.1 | 2026-11-19 | Build fix, shortcut icons, simpler export, Rewards tabs |
| 1.7.0 | 2026-11-19 | Quick picks, daily limit, bill calendar, goals, month recap, shopping list, loans, advances, warranties, accounts |
| 1.6.0 | 2026-11-19 | Payment capture from bank / UPI message notifications (Android) |
| 1.5.1 | 2026-11-19 | Fixes: Undo bar closes itself and is readable, swipe strip fills the row, clearer selected category, paste explained |
| 1.5.0 | 2026-11-19 | Full-body avatars, receipt photos, accessibility, unit tests |
| 1.4.0 | 2026-11-19 | Designed share cards, percent / shares splits, cross-group dues, backup and restore, performance |
| 1.3.0 | 2026-11-19 | Edit group, duplicate-name checks, expense filters, swipe actions, fingerprint / face unlock, Settings screen |
| 1.2.1 | 2026-11-19 | Fixes: sheets close on Save without duplicate records, last item no longer hidden behind the tab bar, Save buttons pinned on long sheets |
| 1.2.0 | 2026-11-19 | First-expense step, shorter Home, free export and basic Insights, notification tone, income and savings, repeat monthly, paste a payment message, Pay by UPI / Remind, undo on delete, app shortcuts, privacy policy |
| 1.1.1 | 2026-11-19 | New opening animation: coins drop into the house, replacing the orbiting-dots one |
| 1.1.0 | 2026-11-19 | Renamed to Gharcha with a house-and-rupee icon; illustrated badges and icons, redrawn avatars, redesigned navigation, forms, themes and celebrations; fixes from device testing of 1.0.3 |
| 1.0.3 | 2026-11-18 | Build fix: PDF export written in-app, `pdf` package removed |
| 1.0.2 | 2026-11-18 | Build fix: Gradle signing block |
| 1.0.1 | 2026-11-18 | Build fix: icons and splash pre-rendered, icon and splash packages removed |
| 1.0.0 | 2026-11-18 | First Gharcha release: Flutter rewrite of HomeQuest 1.9.5 for Android and iOS, new icon and redesigned UI, website download fixed |

Poppins is used under the SIL Open Font License 1.1.
