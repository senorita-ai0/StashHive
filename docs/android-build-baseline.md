# StashHive — Android and Flutter Build Baseline

**Status:** Source configuration committed; validation has deliberately not been run yet. The pinned settings are modeled on the current private FinMate and Stockly projects, with the Gradle wrapper moved to the patched 9.8.1 release.

## Pinned toolchain

| Layer | StashHive setting |
|---|---|
| Flutter SDK in manual GitHub Actions | 3.47.2 |
| Minimum Dart SDK in `pubspec.yaml` | 3.13.2 |
| Minimum Flutter SDK in `pubspec.yaml` | 3.47.2 |
| CI Java runtime | Eclipse Temurin JDK 27 |
| Android Gradle Plugin | 9.4.0 |
| Kotlin Gradle plugin version declaration | 2.4.10 |
| Gradle wrapper | 9.8.1-all |
| Android compile SDK | 36 |
| Android Build Tools | 36.1.0 |
| Java source/target compatibility | 17 |
| Kotlin JVM target | 17 |
| AGP built-in Kotlin | enabled via `android.builtInKotlin=true` |
| Legacy AGP DSL compatibility | `android.newDsl=false` |

JDK runtime and application bytecode targets are intentionally different: Gradle runs on JDK 27, while StashHive and its Kotlin sources target JVM 17. The app module does not apply `org.jetbrains.kotlin.android` when AGP built-in Kotlin is enabled; the version declaration is retained in `settings.gradle.kts` to match the reference projects' plugin-management convention.

Gradle uses 9.8.1 rather than FinMate/Stockly's 9.8.0 wrapper, to take the patch release instead of keeping the earlier wrapper version.

## Generated Android runner

StashHive does not commit generated Android platform files. The manual workflow creates the Android runner if absent, then runs:

- `tool/configure_android_build.py` to normalize AGP/Kotlin/Gradle, SDK/build-tools/JVM targets and generate the custom StashHive adaptive launcher icon resources.
- `tool/configure_android_share_intents.py` to set the app label/icon references and register incoming link, text, image and document share targets.

Both scripts are intended to be idempotent. A second build-configurator run should report no changes. The build configurator does not add Firebase/Google Services plugins or permissions.

## Local setup

Install Flutter 3.47.2, JDK 27, Android SDK platform 36 and Build Tools 36.1.0. If platform runners are missing, run:

```bash
flutter create --project-name stashhive --platforms=android,web .
python3 tool/configure_android_build.py
python3 tool/configure_android_share_intents.py
flutter pub get
```

The Android manifest and adaptive icon resources are generated locally and in the manual validation workflow. They are not represented as committed files in `android/`.

## Validation gate

The configuration scripts and their tests are source-only until the owner triggers **Actions → Manual Flutter validation** on `main`. At that checkpoint, verify the exact Flutter/Dart/Java versions printed by the workflow, then resolve any plugin/AGP issues before using the Android APK for device tests.

This baseline has **not** been proven by a post-change Gradle build, analyzer, formatting run, or test execution. Keep the earlier FilePickerPlugin registration issue open until the manual Android debug APK actually succeeds.

## Official references

- [Gradle release notes](https://docs.gradle.org/current/release-notes.html)
- [Android Gradle Plugin release notes and compatibility](https://developer.android.com/build/releases/about-agp)
- [Flutter: migrate to built-in Kotlin support](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)
- [FinMate Android settings](https://github.com/muhammadnaumantahir/FinMate/blob/main/android/settings.gradle.kts)
- [Stockly Android settings](https://github.com/muhammadnaumantahir/Stockly/blob/main/android/settings.gradle.kts)
