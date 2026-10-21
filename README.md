# StashHive

**Save everything. Find it anytime.**

StashHive is a personal digital library for saving links, notes, screenshots, images, PDFs and documents and finding them later from one local library.

> **Current status: Phase 1 implementation in progress.** A first Flutter increment is in `main`: local persistence, add/edit, metadata search, collections/tags, item details, file selection, backup/restore and settings. The first CI run caught analyzer issues; the latest workflow update distinguishes style-level info lints from errors/warnings. Do not claim the app is verified until the current CI run completes successfully.

## Product principles

- **Local-first:** core use does not require sign-in, a hosted backend or paid AI API.
- **One searchable library:** titles, URLs, notes, tags and collection names are searchable.
- **Fast capture:** manual links and notes first; image/document selection is implemented in the first source slice.
- **Honest content states:** a bookmark is not an offline webpage. A copied attachment is distinct from metadata preview.
- **Portable user data:** export and restore a versioned backup; do not assume local browser/app storage is permanent.
- **Privacy by default:** do not upload or log saved content.

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

OCR/PDF text extraction, Android share-receiver intents, in-app PDF rendering, cloud sync, accounts, public sharing, AI summaries, subscriptions, ads and deployment are not part of the first slice. Search currently covers metadata and user-entered text only.

## Documentation

- [Project intake](docs/PROJECT_INTAKE.md)
- [Requirements and acceptance criteria](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Assumptions](docs/assumptions.md)
- [Roadmap](docs/roadmap.md)
- [Test plan](docs/test-plan.md)
- [Traceability matrix](docs/traceability-matrix.md)
- [Risk register](docs/risk-register.md)
- [Security and privacy](docs/security-privacy.md)
- [Premium Screen Reference — all seven screens](docs/design/screen-reference.md)
- [Design pack](docs/design/README.md)
- [Technical sources](docs/research/official-sources.md)
- [Competitor hypotheses](docs/research/competitor-gap-hypotheses.md)
- [Cost and monetization](docs/cost-and-monetization.md)
- [AI workflow](docs/AI_WORKFLOW.md)
- [Blueprint review](docs/BLUEPRINT_REVIEW.md)
- [Implementation progress](docs/implementation-progress.md)

## Run locally

Install the stable Flutter SDK and Android tooling. If the checkout has no platform runners, generate them once:

```bash
flutter create --project-name stashhive --platforms=android,web .
flutter pub get
dart format lib test
flutter analyze --no-fatal-infos
flutter test
flutter run -d chrome
```

For Android, attach an emulator/device and run `flutter run -d android`. CI generates an Android runner in its workspace when missing, resolves dependencies, formats, analyzes, tests, and builds web plus a debug APK. Check the actual CI result linked from GitHub Actions; no local build is claimed here.

**Data warning:** Android app-private data can disappear on uninstall; browser data can disappear when site data is cleared. Save backups somewhere you control. The Android and browser libraries do not sync.

## License

No repository license has been selected. Do not assume redistribution permissions until the owner chooses one.
