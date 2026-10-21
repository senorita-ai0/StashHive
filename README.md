# StashHive

**Save everything. Find it anytime.**

StashHive is a personal digital library for people who want to save useful things from apps, websites, and their own device—and reliably find them later. Planned item types include screenshots and images, website/article/video links, text snippets, notes, PDFs, and documents.

> **Current status: Blueprint review — product implementation has not started.** The repository currently contains product planning and design artifacts. Do not create the Flutter app or add runtime dependencies until the blueprint is approved.

## Product principles

- **One personal library:** useful content from different sources can be saved and found in one place.
- **Local-first and private by default:** no sign-in, cloud database, or paid AI API is required for the initial core experience.
- **Search before folders:** titles, URLs, notes, tags, and available extracted text should be searchable from one place.
- **Fast capture:** provide manual save and investigate Android share-to-StashHive flows for links, text, images, and selected files.
- **Honest content states:** a saved URL is a bookmark, not an offline website copy. Actual files, previews, and offline snapshots must be labeled separately.
- **Portable user data:** provide a documented export/restore path before calling the local-first MVP complete.
- **No hidden collection:** never upload or log saved content unless a later, explicit, opt-in feature is approved.

## Proposed initial platforms

1. **Android:** primary target for the first useful release, including share/import workflows.
2. **Web:** companion experience built from Flutter for browser use and static hosting. It will have its own browser-local library; cross-device sync is not part of the MVP.
3. **iOS/desktop:** future candidates, not promised until platform-specific storage, imports, and share flows are validated.

Flutter supports browser deployment, but web has different filesystem and browser-storage constraints. Platform differences are called out in the architecture and assumptions documents.

## MVP direction (proposed, not yet approved)

- Add and edit links, text/notes, images, and document references/files.
- Browse a unified library, open details, filter by content type, and use favorites, tags, and collections.
- Search local metadata and text entered by the user.
- Open saved URLs in the browser and files in supported viewers.
- Export and restore a versioned user-controlled backup.
- Use Android share intents for supported incoming text, URLs, images, and selected files after a technical proof of concept.
- Evaluate offline text extraction/OCR separately. English and Urdu/Nastaleeq OCR are not promised until accuracy, package size, platform support, and offline execution are tested.

## Documentation map

- [Project intake](docs/PROJECT_INTAKE.md)
- [Requirements and acceptance criteria](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Assumptions](docs/assumptions.md)
- [Roadmap and task plan](docs/roadmap.md)
- [Test plan](docs/test-plan.md)
- [Traceability matrix](docs/traceability-matrix.md)
- [Risk register](docs/risk-register.md)
- [Security and privacy](docs/security-privacy.md)
- [Design overview](docs/design/README.md)
- [Technical source review](docs/research/official-sources.md)
- [Competitor scan and differentiation hypotheses](docs/research/competitor-gap-hypotheses.md)
- [Cost and monetization plan](docs/cost-and-monetization.md)
- [AI workflow for this repository](docs/AI_WORKFLOW.md)
- [Approval summary](docs/BLUEPRINT_REVIEW.md)

## Before implementation

Read `AGENTS.md` and the files linked above. Review the open assumptions and the proposed storage/share/OCR proof of concept. Implementation is paused until the user explicitly approves the blueprint. See [Blueprint Review Summary](docs/BLUEPRINT_REVIEW.md).

## License

No license has been selected. Do not add a license file or assume reuse permissions until the owner chooses one.
