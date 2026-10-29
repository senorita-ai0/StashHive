# StashHive — Dependency and License Register

**Reviewed:** 29 October 2026  
**Scope:** Direct packages declared in `pubspec.yaml`. This is an initial register, not a completed transitive-license, security-advisory, or legal audit.

## Direct dependencies

| Package | Declared constraint | Role in StashHive | Pub.dev license metadata | Notes |
|---|---|---|---|---|
| Flutter SDK | Flutter SDK dependency | UI framework, navigation, widgets and platform integration | BSD-style license; see [Flutter LICENSE](https://github.com/flutter/flutter/blob/master/LICENSE) | Manual workflow pins Flutter 3.47.2 to match FinMate/Stockly; verify on the manual checkpoint. |
| [crypto](https://pub.dev/packages/crypto/versions/3.0.7) | `^3.0.7` | SHA-256 fingerprints and backup attachment integrity | BSD-3-Clause | Pub.dev currently lists 3.0.8; this constraint permits compatible 3.x releases. The actually resolved version is unknown without a lockfile. |
| [cross_file](https://pub.dev/packages/cross_file) | `^0.3.5` | Cross-platform file objects for shared content and attachment handling | BSD-3-Clause | The constraint excludes 0.4.x. |
| [file_picker](https://pub.dev/packages/file_picker/versions/12.3.0) | `^12.3.0` | User-selected image/document and backup files | MIT | Kept below 13.0 while the candidate Android FilePickerPlugin registration fix remains unverified. Do not upgrade without a deliberate compatibility checkpoint. |
| [hive_ce](https://pub.dev/packages/hive_ce/versions/2.22.0) | `^2.22.0` | Local item, attachment and preference storage engine | Apache-2.0 and BSD-3-Clause listed by Pub.dev | Confirm the notices required by the exact resolved package and bundled components before distribution. |
| [hive_ce_flutter](https://pub.dev/packages/hive_ce_flutter/versions/2.5.0) | `^2.5.0` | Flutter initialization for Hive CE, including browser storage integration | Apache-2.0 and BSD-3-Clause listed by Pub.dev | Verify browser persistence/quota behavior on the validation checkpoint. |
| [receive_sharing_intent](https://pub.dev/packages/receive_sharing_intent/versions/1.9.0) | `^1.9.0` | Receives external Android share intents | Apache-2.0 | Current app integration is Android-only. iOS behavior is not promised or validated. |
| [share_plus](https://pub.dev/packages/share_plus/versions/12.0.2) | `^12.0.2` | Opens the operating-system share sheet for saved content | BSD-3-Clause | Keep platform behavior limited to verified targets; no test/build evidence is claimed for the current source. |
| [url_launcher](https://pub.dev/packages/url_launcher/versions/6.3.3) | `^6.3.3` | Opens validated web links outside the app | BSD-3-Clause | OS handler availability remains a recoverable UI condition. |
| [flutter_lints](https://pub.dev/packages/flutter_lints/versions/6.0.0) | `^6.0.0` (development) | Recommended Dart/Flutter lint rules | BSD-3-Clause | Development-only dependency. |

## Resolution and verification state

- No `pubspec.lock` is committed on `main` as of this review. The exact resolved versions and transitive dependency graph therefore have not been established in this register.
- The app's package constraints and the licenses shown above were checked against Pub.dev package metadata on 28 October 2026. License summaries are a starting point; they do not replace reviewing each license/NOTICE file in the resolved distribution.
- The manual workflow is pinned to Flutter 3.47.2 and JDK 27. Android configuration targets AGP 9.4.0, Kotlin 2.4.10, Gradle 9.8.2, compile SDK 36, Build Tools 36.1.0, and Java/Kotlin bytecode target 17. See `docs/android-build-baseline.md`. This source-level configuration has not yet been validated by an Android build.
- No dependency update or package upgrade was made as part of this register. In particular, keep `file_picker` at its current major constraint until the Android runner compatibility question is tested.
- The dependency audit is **OPEN**: resolve and commit a lockfile at the agreed manual checkpoint, record `flutter pub deps` output, inspect transitive/platform package licenses and notices, check current security advisories, and review whether any notices must be shipped with release artifacts.
- The project has no selected repository license yet. Do not infer that the app itself is licensed for redistribution merely because its dependencies have permissive licenses.

## Official package references

The primary references are the linked Pub.dev package/version pages above. They document current metadata and license files for the declared packages. Recheck them when constraints change or before distributing a release.
