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
A hand-written static site in `website/` with no build step and no shared code with the app, live at https://tehillah.helpfavourv1.workers.dev (Cloudflare, connected by the owner). Pages use clean URLs: `/support` and `/privacy`. It loads no third-party scripts, fonts or cookies: Inter is self-hosted (SIL OFL, license text included). Colors follow the app's light and dark tokens. `_headers` sets security headers and a content-security policy on every response, long immutable caching for fonts and versioned Bible files, and short caching for the manifest and flags file. The home page shows the Google Play and App Store badges, cropped from the owner's image; they are not linked until the store pages exist (the Play URL will be `https://play.google.com/store/apps/details?id=com.zdmgold.tehillah`; the App Store link needs the numeric ID Apple assigns). `tools/check_website.py` runs in the light check and fails on broken local links, missing assets or missing page basics.

## ADR-026: Legal pages (Accepted, 2026-11-18)
Only a short privacy policy and a support page exist. There is no terms page, because the owner states the free game carries no obligations to anyone. The policy is kept short and states only what the app does (ads and consent, local data, store payments, downloads, notifications, age 13+). The support email address appears only on the support page; every other page links to the support page instead. The policy names no publisher or legal entity because none was supplied. The store privacy forms still need the privacy policy URL, which is the `/privacy` page.

## ADR-027: Dependencies and icon set (Accepted, 2026-11-18)
Exact-pinned dependencies resolved on a runner (see `docs/dependencies.md`). Icons come from the Phosphor bold icon font (MIT), bundled as a 49-icon subset because the `phosphor_flutter` package 2.1.0 does not compile on Flutter 3.47.9 (it extends `IconData`, which is now final). The font's stroke is 24/256 of the icon size (2.25 px at 24 px, about 2.06 px at the 22 px interface size), inside the 2.0 to 2.25 stroke rule. One `AppIcon` widget and one alias file (`icon_aliases.dart`) are the only places the icon set is named. Icons that imply direction mirror in right-to-left layouts; every other icon keeps its orientation. The reminder is scheduled inexactly, so no exact-alarm permission is needed.

## ADR-028: Batch p1d scope change (Accepted, 2026-11-18)
`core/errors/app_error.dart` moves from p1f to p1d because the global error handler needs it. The demo `main.dart` and counter test from the generated project are removed; the real `main.dart` arrives in p6a, so the app cannot be built before then. `GlobalErrorHandler` is instance based and takes a log sink, so it is testable and needs no singleton.

## ADR-029: Fonts bundled (Accepted, 2026-11-18)
Four Inter weights (400, 500, 600, 700) and two reading weights (400, 600) as Latin TrueType subsets. The reading face is Source Sans 3 renamed to "Tehillah Reading Sans" because its license reserves the original name for unmodified copies. No italics are bundled. Other scripts use system fonts.

## ADR-030: Match domain models (Accepted, 2026-11-19)
Changes from the blueprint tables for batch p1e, each made so the later logic is simpler and cannot disagree with itself:
- `ShotParams` has four values, not three: `direction` and a new `elevation` (0 ground, 1 crossbar) plus `power` and `curve`, because wide and high misses and the low-shot and high-shot gear effects need a vertical aim.
- The keeper has six places to go (`KeeperDive`: left, centre or right, low or high).
- An opponent carries its `KeeperProfile` directly instead of a profile id, so a `MatchConfig` is fully self-contained for replay. A new `MatchSide` enum (player, opponent) covers Watchman, where the opponent kicks.
- `MatchState` stores counts and scores; whose turn it is and the sudden-death flag are derived from the counts, never stored. A saved state whose counts do not alternate is rejected as corrupt.
- Ball and gear effects are data: one `StatMods` value of additive fractions per item, plus a `GearSpecial` rule for the three effects that are rules (reveal tendency, post to goal once per match, Selah never empties). Unlock thresholds are in lamps (`unlockLamps`) so `progression_rules` reads them from the catalog.
- The stage catalog builds 48 fictional opponents (four per stage) from fixed tables, with no randomness, so the catalog is identical on every device. Boss stages are 6 and 12. All numbers are tuning starting points for the balance simulation in p2b.
- `core` models have no `package:meta`/`equatable` dependency; equality, hashing and copyWith are written by hand, and every `fromJson` throws `FormatException` on bad data so the storage layer can recover.

## ADR-031: Progress, settings and scripture models (Accepted, 2026-11-19)
Batch p1f decisions, adjusting the blueprint tables:
- `Progress` holds everything the blueprint puts in the one JSON file (stars per opponent id, lamps per stage, announced unlocks, achievements, Daily Bread history, bookmarks, highlights) plus the last loadout, running statistics (`ProgressStats`, which the fruit achievements read), a session count (so interstitials never show in the first session), a rating-prompt-shown flag and the current Seven Days run. `schemaVersion` is 1. Missing fields in an older file read as defaults; wrong types or out-of-range values throw `FormatException` so the codec can fall back to the backup. A file with a newer `schemaVersion` is parsed but the codec (p2c) treats it as read-only. Equality compares the canonical saved form (sorted).
- `SettingsModel` reads forgivingly: a bad field falls back to its default and the other settings are kept. Defaults: theme follows the system, reader light, flick input, sound, music and haptics on, reminders off with the time at 18:00, reader text scale 1.0 (range 0.8 to 2.0), packs on Wi-Fi only. Language codes are the ARB codes (`pt_BR`, `zh_Hans`).
- `BiblePack` and `PackManifest` fix the file shapes the p2a tools must write: pack `{schemaVersion, language, translationId, source, license, books{OSIS id: [[verse text]]}}` and manifest `{schemaVersion, packs[{language, translationId, version, url, bytes, sha256, noticePath}]}` with sha256 as 64 lowercase hex digits. Pack verse numbers are the language's own; `VerseRef` (`Book.chapter.verse`, OSIS ids for the 66 books) is the canonical key and the verse-number map (p2c) converts between them.
- Achievements are data: nine fruit entries, each a rule (`AchievementRule`) and a threshold: love 10 wins, joy 50 goals, peace 3 clean sheets, patience 3 sudden-death wins, kindness 10 keeper saves, goodness 6 lamps, faithfulness 7-day Daily Bread streak, gentleness 10 three-star matches, self-control 9 goals in a row. Thresholds are starting values.
- A `LicenseNotice` covers scripture sources, fonts and icons alike, so the licenses screen has one list.

## ADR-034: Pure game logic (Accepted, 2026-11-21)

Batch p2b. Everything below is pure Dart in `core/logic` and `core/input` and is tested on a plain VM.
- Randomness is `SeededRng` (mulberry32). A match forks three streams from its seed (`shot`, `keeper`, `shooter`), and `ShotResolver` always reads the same 14 numbers per kick, so adding a rule never shifts later kicks and a match replays exactly.
- A shot resolves to goal, saved, post, wide or high from aim error (grows with nerve and with power above the ideal 0.78), curve, wind, the six-cell goal grid and the keeper's dive coverage. Save chance is the keeper's skill (60% reaction, 40% reach). Constants were tuned against a Python twin and are held by `balance_simulation_test` (reference player wins about 91% of stage 1 and about 30% of stage 12; no ball above 62% at stage 12).
- The keeper picks a dive from its tendency table; on later stages it blends in the player's own aimed-cell history. The shooter AI (Watchman) and the defender in Sling and Stone scale with difficulty.
- Nerve rises with pressure (sudden death, trailing, boss) and falls with a goal or Selah; Selah charges, Shield, Belt and Helmet are rules in `MatchRules`/`MatchEngine`.
- Daily Bread uses the starter loadout so every player faces the identical challenge. Sling and Stone gives 7 stones for 5 targets; 3, 4 and 5 hits earn 1, 2 and 3 stars.
- Input strategies only emit `ShotParams`; flick and timing bar share one interface.

## ADR-035: Ports, saving and the reader index (Accepted, 2026-11-21)

Batch p2c, adjusting the blueprint.
- **Ports.** `core/ports` declares one small interface per adapter: storage, log, ads, consent, billing, notifications, audio, haptics, share, connectivity, url, pack download and flags. Two ports not in the blueprint table were added (`UrlPort`, `FlagsPort`) because p2d and p2e already list adapters for them. Every port is plain Dart (`Future`/`Stream`) and has an in-memory fake in `test/fakes`.
- **The banner widget.** `AdsPort` exposes only the banner's state and height. The SDK's banner widget cannot be named in `core`; the platform layer will hand the slot a builder through `AppScope` in p2e/p3b.
- **Progress file.** Envelope `{format, sha256, payload}` where the payload is the progress JSON kept as a string, so the checksum is over exact bytes. `Migrator` runs numbered steps from the stored version to the current one, refuses gaps when it is built, and flags a newer version as read-only. `ProgressStore` is the single load/save path: a damaged main file uses the backup, two damaged files start clean with a one-time notice, a newer file is read but never replaced, and a read that throws blocks writes until a load succeeds, so good data is never overwritten by an empty save. A failed write returns a `StorageDegradedError` (warning banner); the app keeps working from memory.
- **Consent.** `ConsentTracker` implements the blueprint rule: a completed refresh is honored, including a decline or withdrawal; a failed refresh never replaces the last saved state, so saved permission survives an offline launch, and with nothing saved ads stay off.
- **Flags.** Every remote flag defaults to on; a missing or mistyped value falls back to on.
- **No verse-number map.** ADR-032 keeps each pack in its own numbering and limits curated verses to chapters whose verse counts agree in all 11 languages, so a canonical reference opens the same verse in every pack. `verse_number_map.dart` and `verse_maps.py` are therefore not built. Bookmarks and highlights carry the language they were saved in and are shown in that language's reader.
- **Verse repository.** Parses `curated.json` and the eleven text files and fails if any language lacks any verse, has an unknown id, or names another language. `forMoment` is deterministic in its seed and skips recently shown ids unless nothing else fits.
- **Reader index.** One inverted index per installed pack. Text is folded (case, Latin accents, Hebrew and Arabic vowel marks); Chinese, Japanese and Korean runs are indexed as overlapping character pairs and verified for adjacency; other words match from three letters as word starts. A synthetic 31,000-verse pack is searched under 250 ms in CI (the target on device is under 50 ms; checked on the emulator in p6c).

## ADR-036: Consent, ads, billing, packs and flags adapters (Accepted, 2026-11-22)

Batch p2e. Platform adapters behind the p2c ports.
- **Consent** (`ConsentService`): Google's User Messaging Platform. `refresh()` updates consent information, shows the form only when the platform says one is required, then reads status, `canRequestAds` and privacy-options requirement. It throws when the update fails so `ConsentTracker` keeps the saved state. A debug geography and test device IDs can be passed for the region tests before release.
- **Ads** (`AdService`): every method first asks a `mayRequest` callback (consent allows, ads not removed, flag on), so the SDK is not even initialized before consent. SDK failures become "no ad" plus a log line. The banner is anchored-adaptive, is exactly its ad's height, and `buildBanner()` returns null (zero height, nothing drawn) unless an ad is ready. The app content rating is capped at teen. Ad units are Google's sample IDs (`AdUnitIds.production` is false) until real IDs are supplied.
- **Billing** (`BillingService`): one non-consumable, `com.zdmgold.tehillah.removeads`. On launch it replays the store's purchases; a purchased or restored event means owned, and the last owned answer is remembered so an offline launch still shows the purchase. An empty answer to a restore the app itself started is the signal that the store holds no purchase (refund), and only then is ownership removed. The rules are the pure function `entitlementAfter`, tested without a store.
- **Packs** (`PackService`): download to `{lang}.part`, one automatic resume with a Range request, SHA-256 check against the manifest, a parse check, then an atomic rename; any failed check discards the file. A language counts as installed only when the pack, notice and meta files are all in place. Requests ask for no content encoding so Cloudflare cannot change the bytes under the hash. Parsing an installed pack runs in a background isolate.
- **Flags** (`FlagsService`): 6 second timeout; a good answer is cached; text that is not a JSON object is ignored and never overwrites the cache; with no answer and no cache every flag is on. `website/flags.json` ships with everything on.
- **Config** (`AppConfig`): the website origin, manifest and flags URLs, support email and product ID live in one file.
- **Network errors**: no connection or a timeout is a user-recoverable error (retry); anything else the server or transfer did is a system-recoverable error.

## Open items

| Item | Status |
| --- | --- |
| iOS permission and app-name strings in the 11 languages (InfoPlist.strings) | Added in batch p6b |
| Cloudflare Pages URL | Pending, owner supplies after batch p1c |
| Launcher icon | Several concepts will be submitted for the owner to choose from before batch p7a |
| Apple team ID and App Store Connect key | Pending, needed only for the iOS release build |
| AdMob production IDs | Pending |

## ADR-032: Scripture sources and packs

Status: accepted.

- Eleven Bibles, one per app language, all from sources whose licence permits redistribution: BSB, RV1909, LSG1910, Lutherbibel 1912, Bíblia Livre (CC BY 4.0), Smith and Van Dyck, Hindi IRV (CC BY-SA 4.0, FreeBiblesIndia), Kougo-yaku, KRV 1961, CUV Simplified, WLC plus Modern Hebrew Bible. Exact files, commits and SHA-256 hashes are pinned in `tools/scripture/sources.json`.
- Every text change is a named rule in `corrections.json`; the builder logs how many verses each rule touched and fails if a rule touches nothing. Nothing is edited by hand in a pack.
- Packs keep each language's own chapter and verse numbering. The reader navigates by the pack's own structure. Chapters whose numbering differs between languages (about 15 to 160 per language, mostly textual-variant differences in the New Testament and Hebrew/German/French Old Testament) are not mapped; the curated verses used in play are limited to chapters with the same verse count in all 11 languages.
- Gaps in a source (about 17 verses in Japanese and Korean, 16 in English, 10 merged verses in Hebrew) stay as empty verses; the reader hides them.
- Some sources place a psalm's superscription inside verse 1 (Spanish, French, Portuguese). Curated verses avoid affected verses.
- Hebrew spacing before the sof pasuq is normalised; cantillation marks are not present in the supplied text.
- CI runs `verify_packs.py` on every push (hash, size, book order, verse count range, spot checks).

## ADR-033: Curated verses

Status: accepted.

- 169 verses are bundled for play moments: miss 46, goal 31, selah 29, win 37, daily 52 (a verse may suit several moments). Chosen for accuracy and fit: comfort after a miss, thanks after a goal, calm at the pause, humility and perseverance at a win, steady daily encouragement.
- Candidates are listed in `tools/scripture/curated_refs.json`; `build_curated.py` keeps one only if its chapter has the same verse count in all 11 languages, no language has a blank, quotation marks balance, it starts a sentence in English and it fits a card (English 200 characters, any language 260). 66 of 235 candidates were dropped by those checks. Four more were excluded by hand with the reason recorded in the file: Gal 5:22–23 and 1 Pet 4:8 (languages split the verses differently), Ps 37:4 (could be read as a promise of winning).
- No verse is chosen as a promise of winning matches.
- Bundled as `app/assets/verses/curated.json` (id, ref, moments) plus `{lang}.json` (id to text). Text is copied from the packs unchanged.

## ADR-037: Providers (p3a)

- **One writer per file.** `SettingsProvider` is the only writer of the settings key; `ThemeProvider` and `LocaleProvider` are thin views that follow it and save through it, so there is one source of truth. `ProgressProvider` is the only writer of the progress file; loadout, bookmarks and achievements save by calling its `update`.
- **Write queue.** A change is applied in memory first and saved afterwards. Writes never overlap and the newest value always wins. A failed write never loses the change: the provider flags it (banner), keeps working from memory and writes again on the next change or on Retry.
- **Safe by construction.** Updates before `load` are ignored and logged, so a default can never overwrite a saved file. A read-only or unreadable store switches saving off and shows the same warning.
- **Achievements and unlocks** are computed inside `applyMatch` / `applyDaily` and returned to the caller (`MatchRecorded`), so the result screen can show them and the file is written once.
- **Entitlement.** Only `EntitlementStatus.owned` sets `adsRemoved`; `unknown` and `pending` keep ads. A restore shows progress until the store answers or 20 seconds pass.
- **Language.** Device languages resolve to the eleven shipped codes (`pt` to `pt_BR`, any `zh` to `zh_Hans`, `iw` to `he`); a manual override always wins. The reader language is separate.

## ADR-038: Feature providers (p3b)

- **One ad decision.** The rules live in `core/ads/ad_policy.dart` as pure functions and are tested as a truth table; `AdProvider` only gathers inputs and drives the ad port. Banner and interstitial need consent, the remote switch and a store answer of "not owned" (unknown or pending requests nothing, so a buyer never sees an ad flash up). An interstitial never shows in the first session and at most once per ten minutes. Rewarded stays available after Remove Ads but still needs consent and its switch.
- **The slot has no height unless an ad is ready.** `bannerHeightDp` is zero whenever the banner is hidden, loading, failed, withdrawn, removed, or the keyboard is open.
- **Daily Bread** uses the device's own calendar day. Reminder text is passed in by the screen because it is localized. On launch a revoked notification permission switches the reminder off.
- **Packs** never download until asked. The provider checks the remote switch, then connectivity (Wi-Fi only fails with `pack.needs_wifi` so the prompt can offer mobile data), then fetches the list and streams progress; every failure becomes a state with an error code.
- **Reader** reads the installed pack for the reader language and remembers the place per language. The search index is built on first search. It follows language, install and text-size changes.
- **Bookmarks and highlights** live in the career file and are written through `ProgressProvider`. Choosing a verse's current highlight colour again removes it.
- **Match** wraps the engine and ignores any call that does not fit the current prompt, so the engine's StateError can never reach the UI. Boss stages (6, 12) are applied in Journey.
- **`AppScope`** carries one `AppServices` container built in `main`; there are no singletons.

## ADR-039: Component library (p4a)

- **One press behaviour.** `Pressable` gives every control a 48 by 48 hit area, button semantics, a keyboard focus ring and opacity or scale feedback (never a ripple). A null `onTap` disables it. Each component picks its own feedback: card and chip fade to 0.7, row tints, button scales to 0.97 and darkens.
- **Six components, no copies.** `AppCard`/`CardSurface`, `AppRow`, `AppChip`, `PrimaryButton` (with `SecondaryButton` and `DestructiveButton`, all filled, never outlined), `SectionHeader`, `EmptyState`, plus `IconChip` (40 inside 48) for every toolbar action.
- **Brand once.** `BrandWordmark` takes its text from the caller; `NavBar.brand` is used on the home screen only, inner screens use `NavBar.back`.
- **Screen shape.** `ScreenFrame` handles the safe area, caps content at 640 wide, and removes the bottom slot entirely while the keyboard is open; the content makes room for the keyboard once.
- **Large text.** Rows and cards wrap rather than clip; at 3.1x text they grow and the screen scrolls. Tests render at 3.1x in left-to-right and right-to-left.
- **Visual gate.** Gate 2 (a screenshot on the cheapest-device profile against a reference app) needs the emulator workflow built in p6c; until then these components are verified by code and widget tests only.
