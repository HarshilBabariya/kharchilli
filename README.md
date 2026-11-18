# Kharchili

Household expenses with spice: log spends in seconds (by voice if you like), split them with the family, keep budgets and get lovingly roasted when you overspend. Points, streaks, badges, avatars and festival packs keep everyone logging. One Flutter codebase for Android and iOS; local-first, no account, no ads.

Kharchili is the rewrite of HomeQuest. Everything about the product, the code and the release process is in **[docs/KHARCHILI.md](docs/KHARCHILI.md)**.

## Get a build
Push to `main`. The **Build and publish** workflow builds the Android APK, proves the iOS app compiles, and publishes the website with that APK behind its download button. The APK is also on the run page as the `Kharchili-apk` artifact.

One-time setup: repo Settings → Pages → Source = **GitHub Actions**.

## Work on it locally
```
bash tool/bootstrap.sh   # flutter create + native settings, icons and splash
flutter run
```

## Ship to the stores
Steps for Google Play (upload key and four repo secrets) and the App Store (Apple Developer account and a Mac) are in section 4 of the reference doc.

## Version history
| Version | Date | Notes |
|---|---|---|
| 1.0.1 | 2026-11-18 | Build fix: icons and splash pre-rendered, icon and splash packages removed |
| 1.0.0 | 2026-11-18 | First Kharchili release: Flutter rewrite of HomeQuest 1.9.5 for Android and iOS, new icon and redesigned UI, website download fixed |

Poppins is used under the SIL Open Font License 1.1.
