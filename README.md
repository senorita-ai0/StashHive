# StashHive

**Save everything. Find it anytime.**

StashHive is a personal digital library for saving links, notes, screenshots, images, PDFs and documents and finding them later from one local library.

> **Current status: Phase 2 source is in progress.** Before Phase 2, dependency resolution, formatting, analysis, unit tests and the web release build passed in GitHub Actions; the Android debug build had not yet finished when CI was switched to manual-only. Phase 2 adds Android incoming-share intake and repository regression tests. Those new changes have not been built/tested yet, by design: builds run only when manually dispatched.

## Product principles

- **Local-first:** core use does not require sign-in, a hosted backend or paid AI API.
- **One searchable library:** titles, URLs, notes, tags and collection names are searchable.
- **Fast capture:** manual links and notes, image/document selection, plus Android incoming-share drafts for supported links, text, images and documents.
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

OCR/PDF text extraction, in-app PDF rendering, cloud sync, accounts, public sharing, AI summaries, subscriptions, ads and deployment remain out of scope. Android incoming shares are now in Phase 2 source but still need device verification. Search currently covers metadata and user-entered text only.

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

For Android, attach an emulator/device and run `flutter run -d android`. The Android share filters are applied by `python3 tool/configure_android_share_intents.py` after a runner is generated. The validation workflow is manual-only; dispatch it from GitHub Actions at a deliberate build checkpoint.

**Data warning:** Android app-private data can disappear on uninstall; browser data can disappear when site data is cleared. Save backups somewhere you control. The Android and browser libraries do not sync.


## Incoming Android shares

The Android share target is included in Phase 2 source, but this repository keeps generated platform runners out of source control. Once Flutter is installed, generate the Android runner if absent and configure the generated manifest:

```bash
flutter create --project-name stashhive --platforms=android,web .
python3 tool/configure_android_share_intents.py
flutter pub get
flutter run -d android
```

The configurator is idempotent and only registers the supported link/text/image/document share types. Incoming items open Quick Save for review; StashHive does not silently save external content. It currently prepares one item per share action. To run verification, open **Actions → Manual Flutter validation → Run workflow**. Pushes to `main` do not start CI.

## License

No repository license has been selected. Do not assume redistribution permissions until the owner chooses one.
