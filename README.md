# StashHive

**Save everything. Find it anytime.**

StashHive is a personal digital library for saving links, notes, screenshots, images, PDFs and documents and finding them later from one local library.

> **Current status: premium UI and Android toolchain alignment are committed to source; verification remains intentionally deferred to the manual checkpoint.** Before Phase 2, dependency resolution, formatting, analysis, unit tests and the web release build passed in GitHub Actions. The Android debug build later failed because the generated Android runner could not resolve the FilePickerPlugin class referenced by GeneratedPluginRegistrant.java. The file_picker dependency was moved to 12.3.0 as a candidate fix for the known 11.x/AGP 9 issue; it is not verified until the manual build. CI is manual-only, and no post-Phase 2/3 build or test has been run.

## Product principles

- **Local-first:** core use does not require sign-in, a hosted backend or paid AI API.
- **One searchable library:** titles, URLs, notes, tags and collection names are searchable.
- **Fast capture:** manual links and notes, image/document selection, plus Android incoming-share drafts for supported links, text, images and documents.
- **Honest content states:** a bookmark is not an offline webpage. A copied attachment is distinct from metadata preview.
- **Portable user data:** export and restore a versioned backup; do not assume local browser/app storage is permanent.
- **Privacy by default:** do not upload or log saved content.

## Product identity and compatibility

The current user-facing brand is **StashHive**. The Dart package name (`stashhive`), Hive store keys (`stashhive_*_v1`) and version-1 JSON backup marker (`StashHive`) are retained. Import compatibility for older StashTrail backups is preserved.

The visual system now uses the shared premium component kit from FinMate and Stockly, adapted to StashHive's own library flows and hive branding. This includes the blue/mint palette, Material 3 typography, rounded cards and controls, common page headers, hero panels and empty states.

## Proposed platforms

1. **Android:** primary target, including share/import support after its technical implementation and device verification.
2. **Web:** companion target using browser-local storage. Browser data is separate from Android; there is no automatic cross-device sync.
3. **iOS/desktop:** not promised until platform-specific storage/import behavior has been validated.

## First implementation slice

- Four destinations: Library, Search, Collections, Settings.
- Save/edit links and notes; pick image/document files.
- Local metadata search, item details, open links externally, preview images, favorite/delete.
- Collections and tags.
- Versioned JSON backup/restore (15 MB per attachment, 100 MB combined attachment bytes).
- Dark appearance toggle.

OCR/PDF text extraction, in-app PDF rendering, cloud sync, accounts, public sharing, AI summaries, subscriptions, ads and deployment remain out of scope. Android incoming shares are now in Phase 2 source but still need device verification. Search currently covers metadata and user-entered text only.

## Documentation

- [Project intake](docs/PROJECT_INTAKE.md)
- [Requirements and acceptance criteria](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Assumptions](docs/assumptions.md)
- [Roadmap](docs/roadmap.md)
- [Test plan](docs/test-plan.md)
- [Dependency and license register](docs/dependency-register.md)
- [Android and Flutter build baseline](docs/android-build-baseline.md)
- [Traceability matrix](docs/traceability-matrix.md)
- [Risk register](docs/risk-register.md)
- [Security and privacy](docs/security-privacy.md)
- [Premium Screen Reference — all seven screens](docs/design/screen-reference.md)
- [Design pack](docs/design/README.md)
- [Technical sources](docs/research/official-sources.md)
- [Local PDF/OCR feasibility](docs/research/local-text-extraction-feasibility.md)
- [Competitor hypotheses](docs/research/competitor-gap-hypotheses.md)
- [Prioritized feature backlog](docs/FEATURE_BACKLOG.md)
- [Cost and monetization](docs/cost-and-monetization.md)
- [AI workflow](docs/AI_WORKFLOW.md)
- [Blueprint review](docs/BLUEPRINT_REVIEW.md)
- [Implementation progress](docs/implementation-progress.md)
- [Performance benchmark guide](docs/performance-benchmark.md)

## Run locally

Use **Flutter 3.47.2** and **JDK 27** for the current Android baseline. The generated Android build is normalized to **AGP 9.4.0**, **Kotlin 2.4.10**, **Gradle 9.8.2**, compile SDK 36 and Build Tools 36.1.0. If the checkout has no platform runners, generate them once and apply the two StashHive configurators:

```bash
flutter create --project-name stashhive --platforms=android,web .
python3 tool/configure_android_build.py
python3 tool/configure_android_share_intents.py
flutter pub get
```

For normal local development, run `flutter run -d chrome` or attach an emulator/device and run `flutter run -d android`. The formatting, analyzer, tests and builds are deliberately not run by source updates; the GitHub Actions workflow remains manual-only. Review [the Android build baseline](docs/android-build-baseline.md) before intentionally running the final validation checkpoint.

**Data warning:** Android app-private data can disappear on uninstall; browser data can disappear when site data is cleared. Save backups somewhere you control. The Android and browser libraries do not sync.


## Incoming Android shares

The Android share target is included in Phase 2 source, but this repository keeps generated platform runners out of source control. Once Flutter is installed, generate the Android runner if absent and configure the generated manifest:

```bash
flutter create --project-name stashhive --platforms=android,web .
python3 tool/configure_android_share_intents.py
flutter pub get
flutter run -d android
```

The Android build configurator aligns the generated Gradle/JDK/Flutter toolchain and writes the blue-and-mint adaptive hive launcher assets. The share configurator is idempotent, sets the StashHive label/icon references and registers supported link/text/image/document share types. Incoming batches are reviewed sequentially in Quick Save, one draft at a time; each supported item must be explicitly saved or canceled, and unsupported items are skipped with feedback. StashHive does not silently save external content. To run verification, open **Actions → Manual Flutter validation → Run workflow**. Pushes to `main` do not start CI.

## License

No repository license has been selected. Do not assume redistribution permissions until the owner chooses one.
