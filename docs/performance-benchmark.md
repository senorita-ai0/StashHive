# StashTrail — Local Performance Baseline

## Purpose

The metadata-only benchmark harness supports NFR-007 by collecting an environment-specific baseline for a library of 100, 1,000, and 10,000 saved links. It reports measurements; it does not impose arbitrary latency thresholds or claim the product meets a performance target.

## Run deliberately

From the repository root, after the Flutter SDK is installed and dependencies have been resolved:

```bash
flutter pub get
dart run tool/benchmark_library_repository.dart
```

The tool seeds a temporary local Hive database for each dataset size. It removes the temporary directory afterward and does not modify the user's actual library. It does not trigger GitHub Actions.

## Measurements reported

- **bulkSeedMs** — time to bulk-write the raw metadata fixture.
- **openAndValidateMs** — time to open the repository and materialize/validate the saved-item records.
- **searchAverageMicroseconds** — average of 25 metadata searches for a term present in a small, predictable subset.
- **favoriteFilterAverageMicroseconds** — average of 25 favorite filters.
- **editExistingItemMs** — time to save one edit to an existing item, including the repository's refresh and validation work.
- **backupEncodeMs** and **backupCharacters** — time and encoded JSON string length for a metadata-only versioned backup.

The fixtures use valid links, tags, collection assignments and bounded timestamps; there are no attachment payloads. Therefore the results do **not** replace Android/web testing, attachment-memory profiling, or backup/restore integrity tests.

## Recording and interpretation

Run on a representative machine and record the date, OS, Flutter/Dart versions, and the JSON output in the validation record before comparing future runs. Close unrelated CPU-heavy applications, avoid comparing measurements from very different devices or runtime modes, and rerun surprising results. Do not add CI latency assertions based on one machine's timings. Establish acceptance thresholds only after a baseline and target-device expectations have been reviewed.

## Current status

**Harness added; measurements not run.** CI is intentionally manual-only. Results and platform verification remain pending until the owner requests the agreed validation checkpoint.
