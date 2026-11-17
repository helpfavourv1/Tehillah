# Tehillah Soccer

A 2D penalty-shootout football game with a scripture theme, built once in Flutter and Flame for Android and iOS.

- Store title: Tehillah Soccer: Penalty Shootout Game
- Application ID (Android and iOS): `com.zdmgold.tehillah`
- Languages: English, Spanish, French, German, Brazilian Portuguese, Arabic, Hindi, Japanese, Korean, Simplified Chinese, Hebrew
- Support: stmakarios@gmail.com

## Repository map

| Path | What it is |
| --- | --- |
| `app/` | The Flutter and Flame application |
| `website/` | Static marketing site, privacy and support pages, and the downloadable Bible packs under `website/scripture/` |
| `tools/` | Build tools (scripture extraction and packing, audio synthesis, string and translation checks) |
| `docs/` | Decision log, identity tracking, scripture sources, runbook |
| `store_submission/` | Store listing text, data-safety answers, screenshot plan |
| `.github/workflows/` | `check.yml` runs on every push; builds and emulator runs are manual only |
| `codemagic.yaml` | iOS build configuration |

`app/`, `website/` and `tools/` share no code and no build trigger.

## How a batch lands

1. A batch is pushed to the `ci-analyser` branch.
2. `check.yml` runs on that push. Its result and logs are read and any failure is fixed on that branch.
3. Only a green commit is pushed to `main`.

The commit message form is `<batch-id>: <purpose>`, for example `p1d: design tokens and icon wrapper`, so `git log` reads as the build trail. To confirm a batch landed, open the repository on github.com and check the paths named in the batch report.

## Builds

APK and AAB builds run only from the **Actions** tab by choosing the build workflow and pressing **Run workflow**. There is no push-triggered build.

## Decisions

Every decision and every change of plan is recorded in [`docs/decision.md`](docs/decision.md).
