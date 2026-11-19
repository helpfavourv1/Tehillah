# Dependencies

Every dependency is pinned to an exact version in `app/pubspec.yaml` and recorded in `app/pubspec.lock`. Versions were resolved on a GitHub runner with Flutter 3.47.9 (Dart 3.13.7) on 2026-11-18 and each package's own documentation and Android manifest were read before use.

| Package | Version | Used for |
| --- | --- | --- |
| flame | 1.38.2 | The 2D match engine |
| google_mobile_ads | 9.2.0 | AdMob ads and the consent platform (UMP) |
| in_app_purchase | 3.3.1 | The one-time Remove Ads purchase |
| shared_preferences | 2.5.6 | Settings key-value storage |
| path_provider | 2.1.6 | Folder for the progress file and downloaded Bibles |
| flutter_local_notifications | 23.0.2 | The opt-in Daily Bread reminder |
| timezone | 0.11.2 | Scheduling the reminder at a local time |
| flutter_timezone | 5.1.1 | Reading the device time zone for the reminder |
| share_plus | 13.3.1 | Sharing a verse |
| connectivity_plus | 7.3.2 | Wi-Fi-only choice for the Bible download |
| url_launcher | 6.3.3 | Opening the support email and license links |
| intl | 0.20.3 | Locale-aware numbers, dates and plurals |
| crypto | 3.0.8 | SHA-256 checks of downloaded Bibles and the progress file |
| audioplayers | 6.8.1 | Sound effects and the menu music loop |
| phosphor_flutter | 2.1.0 | The icon set (bold weight); its font is a direct dependency so it bundles |
| flutter_localizations (SDK) | Flutter 3.47.9 | Localization delegates for the 11 languages |
| flutter_lints (dev) | 6.0.0 | Static analysis rules |

## Platform requirements read from the packages

- Android minimum SDK: google_mobile_ads and flutter_local_notifications both require 24. The app uses Flutter's default, which is 24 or higher.
- flutter_local_notifications needs RECEIVE_BOOT_COMPLETED and two receivers in the Android manifest so reminders survive a reboot. The reminder is scheduled inexactly, so no exact-alarm permission is declared.

## Policy

- Exact pins only; no carets or ranges. A new version is adopted deliberately, in its own batch, with the changelog read.
- Lock file committed. The light check runs `flutter pub get` against it.
- Before each release: check every direct dependency for a published security advisory, and re-read the licenses of all packages. The in-app licenses screen lists the Flutter and package licenses through Flutter's license registry, plus the font and scripture notices.
- No dependency is added unless a capability in the blueprint needs it.

## Bundled fonts

Inter (SIL OFL 1.1) and Source Sans 3 (SIL OFL 1.1, bundled as the renamed subset "Tehillah Reading Sans"). Latin subsets only, about 536 KB in total for six files. `tools/fonts/subset_fonts.py` rebuilds them. The license texts are in `app/assets/fonts/`.
