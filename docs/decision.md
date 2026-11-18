# Decision log

Each entry records what was decided, why, and when. A change of plan is added as a new entry that supersedes the old one; old entries are never deleted. The master blueprint (Claude Doc "Tehillah Soccer — Master Blueprint") holds the full specification; this file holds the decisions that govern the build.

Status values: Accepted, Superseded, Open.

## ADR-001: Engine and language (Accepted, 2026-11-15)
Flutter with the Flame engine, Dart, one codebase, 2D, for Android and iOS. A 2D penalty shootout is achievable to a premium finish by one developer; 11-a-side 3D is not.

## ADR-002: Own chrome, no Material or Cupertino widgets (Accepted, 2026-11-15)
The app shell is `WidgetsApp` with its own component library (card, row, chip, primary button, section header, empty state). Flat filled surfaces, hairline borders, no elevation, no ripple, opacity-only press feedback. Reason: the look must belong to the product, not to a widget library.

## ADR-003: State management (Accepted, 2026-11-15)
`ValueNotifier` over immutable state, one provider per state domain, bound with `ListenableBuilder`. No `setState` for business logic. Services are built once in `main` and handed down through an `AppScope` inherited widget, with no global singletons.

## ADR-004: Layering (Accepted, 2026-11-15)
`lib/core` is pure Dart (no `dart:io`, no Flutter, no plugins) and is unit-testable on a plain VM. `lib/platform` implements interfaces declared in `core`. An architecture test fails the build if `core` imports anything else.

## ADR-005: Determinism (Accepted, 2026-11-15)
A match outcome is a pure function of the shot, the keeper roll and a seed. This allows headless balance simulation and an identical Daily Bread for every player each day.

## ADR-006: Scripture delivery (Accepted, 2026-11-16; supersedes the earlier "download everything on first install")
Curated verses for all 11 languages are bundled in the app. The full Bible is one compressed file per language on Cloudflare Pages, downloaded only when the user first uses the reader, with a Wi-Fi-only or Wi-Fi-and-mobile-data choice. Every pack is verified by SHA-256 and installed atomically. The reader language is independent of the app language. Full details are in the blueprint, section 5.

## ADR-007: Scripture sources (Accepted, 2026-11-16)
English BSB, Spanish RV1909, French LSG 1910, German Luther 1912, Portuguese (Brazil) Bíblia Livre, Arabic SVD 1865, Hindi Indian Revised Version 2019, Japanese Kougo-yaku 1954/55, Korean Revised Version 1961, Simplified Chinese CUV, Hebrew (Old Testament WLC, New Testament Modern Hebrew Bible). All text is extracted by script, never retyped. Open verification items: French provenance, Japanese public-domain status, Hindi notice re-read, Luther verse map, Korean empty verses.

## ADR-008: Ads and consent (Accepted, 2026-11-17)
AdMob with Google's sample IDs during the build; production IDs only when the owner supplies them. UMP is the consent platform and every ad request is gated on its `canRequestAds` result. A failed or offline refresh never overrides saved consent. A declined consent does not by itself stop requests; the app follows UMP's result and Google determines what is served. Where a required form is unanswered, no request is made. A Privacy choices row appears in Settings when UMP requires it. Ad SDK failure collapses the slot silently.

## ADR-009: Ad placement and frequency (Accepted, 2026-11-17)
- Banner: menu screens only, never in a match or the reader.
- Interstitial: only at natural breaks (the Result screen's Continue, and returning to the Journey map after a stage is cleared). Never during a kick or match, in the reader, onboarding, Settings or the purchase screen. Minimum gap 10 minutes, counted from the last interstitial or from app start. No daily cap and no session cap. Never in the very first session.
- Rewarded, always opt-in and never required for any unlock: extra Selah for the next match; streak rescue for one missed Daily Bread or Seven Days day; extra stones in Sling and Stone; retry a lost Journey match once.
- Sensitive ad categories are blocked in the AdMob console (owner step).

## ADR-010: Monetization (Accepted, 2026-11-17)
One non-consumable purchase, `com.zdmgold.tehillah.removeads`, removes the banner and interstitials. Rewarded ads remain available after purchase because they are opt-in. No unlock is ever sold. Restore purchase is always visible in Settings; the paywall is never a blocking modal.

## ADR-011: Audio (Accepted, 2026-11-17)
Sound effects (kick, goal, save, post, miss, whistle, Selah, tap) and one original menu music loop, both synthesized by script with a fixed seed so there is no licensing risk. Music has its own off switch in Settings.

## ADR-012: Remote flags (Accepted, 2026-11-17)
A static `flags.json` on Cloudflare Pages is read at launch with a timeout and cache. It can switch off ads, the reader download or a feature without a new build. If it cannot be reached the app uses built-in defaults. It carries no user data.

## ADR-013: Crash and diagnostic reporting (Accepted, 2026-11-17)
No analytics or crash-reporting SDK. A rotating local log is kept on the device and the user can email the debug lines to support from the error screen or Settings. This keeps the privacy label minimal.

## ADR-014: Translation review (Accepted, 2026-11-17)
The ten non-English interface languages are drafted and checked by Claude with a back-translation to English shown side by side for every string in every language. No separate reviewer is used after the build. Because no native-speaker review takes place, each language is recorded here as "unreviewed by a native speaker" and the store listing makes no claim otherwise. The back-translation reports are kept in `docs/l10n_review/`.

## ADR-015: Rating prompt (Accepted, 2026-11-17)
One rating prompt, after a stage win, never after a loss.

## ADR-016: Store category (Accepted, 2026-11-17)
Games, Sports. The store listing leads with the game; the Bible reader is a secondary feature.

## ADR-017: CI model (Accepted, 2026-11-17)
The light check (`check.yml`) runs on every push to any branch and never builds an app or signs anything. Builds and emulator runs are `workflow_dispatch` only, with no push trigger ever. Each batch goes to `ci-analyser` first; only a green commit goes to `main`.

## ADR-018: Toolchain pin (Accepted, 2026-11-17)
Flutter 3.47.9 stable (Dart 3.13.7) is pinned exactly in CI and was confirmed to install on the runner by the bootstrap workflow on 2026-11-17 (the newer 3.50.0 was released days earlier and is not used for a pin). The pubspec Dart constraint is recorded in batch p1d. The pin is never floating `stable`.

## ADR-019: Repository visibility and license (Accepted, 2026-11-17)
The repository is public during the build so CI minutes are unmetered, and is changed to private after the build. No license file is added, so the code is all rights reserved. The in-app licenses screen is separate and lists every third-party and scripture notice. Note: GitHub's free plan meters private-repository Actions minutes, so manual builds after the switch use that quota.

## ADR-020: Language set (Accepted, 2026-11-15)
en, es, fr, de, pt_BR, ar, hi, ja, ko, zh_Hans, he. Arabic and Hebrew are right-to-left through `Directionality`. Layouts use start and end, never left and right.

## ADR-021: Content rules (Accepted, 2026-11-15)
No depiction of God, Jesus, angels or saints in art or animation. Misses are met with encouragement. No luck mechanics and no claim that prayer or Selah gives a spiritual or competitive advantage. Opponents are fictional. Audience 13 and over.

## ADR-022: Fonts (Accepted, 2026-11-18)
Two open-license (SIL OFL) Latin faces are bundled: Inter and Source Sans 3. Working assignment, to be confirmed before batch p1d: Inter for the brand, buttons and menus; Source Sans 3 for verse and reader text. Arabic, Hindi, Japanese, Korean, Chinese and Hebrew use the platform's system fonts. Measured Latin web-format sizes for four weights: Inter 97 KB, Source Sans 3 63 KB; the in-app TrueType files will be larger and are measured in p1d.

## ADR-023: Platform manifests (Accepted, 2026-11-18)
- Android permissions, each tied to a capability in the blueprint: INTERNET and ACCESS_NETWORK_STATE (ads, pack download, connectivity check), com.google.android.gms.permission.AD_ID (ads), POST_NOTIFICATIONS (opt-in Daily Bread reminder, requested at the time of use), VIBRATE (haptics). RECEIVE_BOOT_COMPLETED and the notification receivers are added in the batch that pins the notification plugin, after its documentation is read.
- Android `queries` allow https links and mailto (license links, support email). iOS `LSApplicationQueriesSchemes` mirrors this.
- Android `allowBackup` is off so local progress is not restored into an inconsistent state on another device.
- AdMob app IDs are Google's documented sample IDs, taken from Google's official `google_mobile_ads` example project (Android `ca-app-pub-3940256099942544~3347511713`, iOS `ca-app-pub-3940256099942544~1458002511`). They are replaced by production IDs only when the owner supplies them.
- iOS: `NSUserTrackingUsageDescription` and 50 `SKAdNetworkItems` taken from Google's AdMob iOS privacy-strategies page on 2026-11-18. The list is re-checked against Google's page and the SDK version when the iOS build is first run.
- iOS `PrivacyInfo.xcprivacy` is registered in the Xcode project resources. It declares tracking (the app asks for tracking permission), no tracking domains and no collected data types of its own (the ad SDK ships its own privacy manifest), and the UserDefaults required-reason API (CA92.1) for settings. The App Store Connect privacy answers are written separately in `store_submission/DATA_BACKING.md` (batch p7c).
- Android release signing reads `android/key.properties`, written by the release workflow from secrets and never committed. Without it the build falls back to the debug key; the release workflow (batch p7b) fails if the file is missing so an unsigned-by-intent release can never ship.
- The iOS project could not be compiled on the Linux runner; it is first built by Codemagic.

## ADR-024: Orientation and device range (Accepted, 2026-11-18)
Portrait and landscape are both supported on every screen and in the match. The Redmi A5 is the cheapest test target, not the only supported device, so layouts must also work on larger phones, tablets and foldables. The emulator runs in batch p6c cover both orientations. The generated Android and iOS projects already allow both and stay that way.

## ADR-025: Website (Accepted, 2026-11-18)
A hand-written static site in `website/` with no build step and no shared code with the app. It loads no third-party scripts, fonts or cookies: Inter is self-hosted (SIL OFL, license text included). Colors follow the app's light and dark tokens. `_headers` sets security headers, a content-security policy for pages, long immutable caching for fonts and versioned Bible files, and short caching for the manifest and flags file. The privacy policy names no publisher or legal entity because none was supplied; it gives the support email as the contact. `tools/check_website.py` runs in the light check and fails on broken local links, missing assets or missing page basics.

## Open items

| Item | Status |
| --- | --- |
| Font role split (Inter for chrome, Source Sans 3 for verse and reader text) | Confirm before p1d |
| iOS permission and app-name strings in the 11 languages (InfoPlist.strings) | Added in batch p6b |
| Cloudflare Pages URL | Pending, owner supplies after batch p1c |
| Launcher icon | Several concepts will be submitted for the owner to choose from before batch p7a |
| Apple team ID and App Store Connect key | Pending, needed only for the iOS release build |
| AdMob production IDs | Pending |
