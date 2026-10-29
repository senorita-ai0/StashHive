#!/usr/bin/env python3
"""Align Flutter's generated Android runner with StashHive's shared build baseline.

This runs after `flutter create` when the generated Android project is missing.
It intentionally does not add Google/Firebase plugins or app permissions.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ANDROID_PLUGIN_VERSION = "9.4.0"
KOTLIN_PLUGIN_VERSION = "2.4.10"
GRADLE_VERSION = "9.8.2"
COMPILE_SDK = 36
BUILD_TOOLS_VERSION = "36.1.0"
JAVA_TARGET = 17

LAUNCHER_RESOURCES = {
    "app/src/main/res/values/stashhive_colors.xml": """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="stashhive_launcher_background">#2563EB</color>
</resources>
""",
    "app/src/main/res/drawable/stashhive_launcher_foreground.xml": """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="3.5"
        android:strokeLineJoin="round"
        android:pathData="M54,17 L67,24.5 L67,39.5 L54,47 L41,39.5 L41,24.5 Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="3.5"
        android:strokeLineJoin="round"
        android:pathData="M37,38 L50,45.5 L50,60.5 L37,68 L24,60.5 L24,45.5 Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="3.5"
        android:strokeLineJoin="round"
        android:pathData="M71,38 L84,45.5 L84,60.5 L71,68 L58,60.5 L58,45.5 Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="3.5"
        android:strokeLineJoin="round"
        android:pathData="M54,59 L67,66.5 L67,81.5 L54,89 L41,81.5 L41,66.5 Z" />
    <path
        android:fillColor="#17C7A1"
        android:pathData="M54,43 L62,47.5 L62,56.5 L54,61 L46,56.5 L46,47.5 Z" />
</vector>
""",
    "app/src/main/res/drawable/stashhive_launcher_legacy.xml": """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="24dp" />
            <solid android:color="@color/stashhive_launcher_background" />
        </shape>
    </item>
    <item android:drawable="@drawable/stashhive_launcher_foreground" />
</layer-list>
""",
    "app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml": """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/stashhive_launcher_background" />
    <foreground android:drawable="@drawable/stashhive_launcher_foreground" />
</adaptive-icon>
""",
    "app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml": """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/stashhive_launcher_background" />
    <foreground android:drawable="@drawable/stashhive_launcher_foreground" />
</adaptive-icon>
""",
}

GRADLE_PROPERTIES = {
    "org.gradle.jvmargs": (
        "-Xmx4G -XX:+HeapDumpOnOutOfMemoryError -XX:MaxMetaspaceSize=1G "
        "-Dfile.encoding=UTF-8 --enable-native-access=ALL-UNNAMED"
    ),
    "android.useAndroidX": "true",
    # Required while Flutter/plugins still use the legacy AGP DSL APIs.
    "android.newDsl": "false",
    # Flutter 3.47+ can opt in to AGP 9's built-in Kotlin integration.
    "android.builtInKotlin": "true",
    "kotlin.incremental": "false",
    "kotlin.incremental.useClasspathSnapshot": "false",
    "kotlin.compiler.execution.strategy": "daemon",
    "kotlin.daemon.enabled": "true",
}

SDK_CONFIGURATION_MARKER = "// STASHHIVE_SHARED_ANDROID_SDK_CONFIGURATION"
SDK_CONFIGURATION_BLOCK = f"""
{SDK_CONFIGURATION_MARKER}
subprojects {{
    pluginManager.withPlugin("com.android.library") {{
        extensions.configure<LibraryExtension> {{
            compileSdk = {COMPILE_SDK}
            buildToolsVersion = "{BUILD_TOOLS_VERSION}"
        }}
    }}

    pluginManager.withPlugin("com.android.application") {{
        extensions.configure<ApplicationExtension> {{
            compileSdk = {COMPILE_SDK}
            buildToolsVersion = "{BUILD_TOOLS_VERSION}"
        }}
    }}

    // Keep third-party plugins that still expose the old AGP extension aligned.
    afterEvaluate {{
        val androidExt = extensions.findByName("android")
        if (androidExt is BaseExtension) {{
            androidExt.compileSdkVersion({COMPILE_SDK})
            androidExt.buildToolsVersion = "{BUILD_TOOLS_VERSION}"
        }}
    }}
}}
"""


def _replace_one(pattern: str, replacement: str, text: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"Could not find exactly one {label} to configure.")
    return updated


def _set_property(text: str, key: str, value: str) -> str:
    """Set one gradle.properties key, removing duplicate assignments."""
    lines = text.splitlines()
    result: list[str] = []
    inserted = False
    prefix = key + "="
    for line in lines:
        if line.lstrip().startswith(prefix):
            if not inserted:
                result.append(f"{key}={value}")
                inserted = True
            continue
        result.append(line)
    if not inserted:
        result.append(f"{key}={value}")
    return "\n".join(result).rstrip() + "\n"


def _write_if_changed(path: Path, content: str) -> bool:
    if path.is_file() and path.read_text(encoding="utf-8") == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    return True


def configure_android_build(android_dir: str | Path) -> list[str]:
    """Configure the generated Android runner; return modified relative paths."""
    root = Path(android_dir)
    settings_path = root / "settings.gradle.kts"
    root_build_path = root / "build.gradle.kts"
    app_build_path = root / "app" / "build.gradle.kts"
    wrapper_path = root / "gradle" / "wrapper" / "gradle-wrapper.properties"
    properties_path = root / "gradle.properties"

    required = (
        settings_path,
        root_build_path,
        app_build_path,
        wrapper_path,
        properties_path,
    )
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError(
            "Generated Android runner is incomplete; missing: " + ", ".join(missing)
        )

    changed: list[str] = []
    settings = settings_path.read_text(encoding="utf-8")
    for plugin_id, version in (
        ("com.android.application", ANDROID_PLUGIN_VERSION),
        ("org.jetbrains.kotlin.android", KOTLIN_PLUGIN_VERSION),
    ):
        pattern = (
            r'(^\s*id\(["\']'
            + re.escape(plugin_id)
            + r'["\']\)\s+version\s+["\'])[^"\']+(["\']\s+apply false\s*$)'
        )
        settings = _replace_one(
            pattern,
            lambda_match(version),
            settings,
            f"{plugin_id} plugin version",
        )
    if _write_if_changed(settings_path, settings):
        changed.append(str(settings_path.relative_to(root)))

    wrapper = wrapper_path.read_text(encoding="utf-8")
    wrapper = _replace_one(
        r"^distributionUrl=.*$",
        f"distributionUrl=https\\://services.gradle.org/distributions/gradle-{GRADLE_VERSION}-all.zip",
        wrapper,
        "Gradle wrapper distributionUrl",
    )
    if _write_if_changed(wrapper_path, wrapper):
        changed.append(str(wrapper_path.relative_to(root)))

    properties = properties_path.read_text(encoding="utf-8")
    for key, value in GRADLE_PROPERTIES.items():
        properties = _set_property(properties, key, value)
    if _write_if_changed(properties_path, properties):
        changed.append(str(properties_path.relative_to(root)))

    app_build = app_build_path.read_text(encoding="utf-8")
    # AGP 9.4 provides built-in Kotlin support. FinMate and Stockly leave the
    # Kotlin plugin declared in settings for compatibility but do not apply it
    # to the app module when android.builtInKotlin=true.
    # Flutter templates have used both the fully qualified plugin id and
    # the short kotlin-android alias. Remove either legacy KGP application
    # when AGP built-in Kotlin is enabled.
    for legacy_kotlin_plugin_pattern in (
        r"""(?m)^\s*id\([\"']org\.jetbrains\.kotlin\.android[\"']\)\s*\n""",
        r"""(?m)^\s*id\([\"']kotlin-android[\"']\)\s*\n""",
    ):
        app_build = re.sub(legacy_kotlin_plugin_pattern, "", app_build)
    app_build = _replace_one(
        r"^(\s*compileSdk\s*=\s*)(?:flutter\.compileSdkVersion|\d+)(\s*)$",
        rf"\g<1>{COMPILE_SDK}\g<2>",
        app_build,
        "app compileSdk",
    )
    # The shared root configuration sets Build Tools for app and library
    # projects. Preserve the reference projects' module-level Gradle structure;
    # only normalize buildToolsVersion here if a local template already sets it.
    if re.search(r"(?m)^\s*buildToolsVersion\s*=", app_build):
        app_build = _replace_one(
            r"^(\s*buildToolsVersion\s*=\s*)[^\n]+$",
            rf'\g<1>"{BUILD_TOOLS_VERSION}"',
            app_build,
            "app buildToolsVersion",
        )

    app_build = re.sub(
        r"(?m)^(\s*(?:sourceCompatibility|targetCompatibility)\s*=\s*)JavaVersion\.VERSION_\d+\s*$",
        rf"\g<1>JavaVersion.VERSION_{JAVA_TARGET}",
        app_build,
    )
    if "kotlin {\n    compilerOptions {" not in app_build:
        flutter_block = re.search(r"(?m)^flutter\s*\{", app_build)
        if flutter_block is None:
            raise ValueError("Could not find the Flutter Gradle configuration block.")
        kotlin_block = (
            "kotlin {\n"
            "    compilerOptions {\n"
            "        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17\n"
            "    }\n"
            "}\n\n"
        )
        app_build = app_build[:flutter_block.start()] + kotlin_block + app_build[flutter_block.start():]
    if _write_if_changed(app_build_path, app_build):
        changed.append(str(app_build_path.relative_to(root)))

    root_build = root_build_path.read_text(encoding="utf-8")
    imports = (
        "import com.android.build.api.dsl.ApplicationExtension\n"
        "import com.android.build.gradle.BaseExtension\n"
        "import com.android.build.gradle.LibraryExtension\n"
    )
    missing_imports = [
        line for line in imports.splitlines(keepends=True)
        if line.strip() not in root_build
    ]
    if missing_imports:
        root_build = "".join(missing_imports) + root_build
    if SDK_CONFIGURATION_MARKER not in root_build:
        root_build = root_build.rstrip() + "\n\n" + SDK_CONFIGURATION_BLOCK.lstrip() + "\n"
    if _write_if_changed(root_build_path, root_build):
        changed.append(str(root_build_path.relative_to(root)))

    # Custom branded icon resources replace Flutter's generated starter mark.
    # The adaptive resources cover Android 8+; the legacy vector layer-list is
    # referenced by the manifest as the fallback on older supported Android.
    for relative_path, resource_content in LAUNCHER_RESOURCES.items():
        resource_path = root / relative_path
        if _write_if_changed(resource_path, resource_content):
            changed.append(relative_path)

    return changed


def lambda_match(version: str):
    """Create a regex replacement that preserves the original plugin syntax."""
    return lambda match: match.group(1) + version + match.group(2)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--android-dir",
        default="android",
        help="Generated Android runner directory (default: android).",
    )
    args = parser.parse_args()
    try:
        changed = configure_android_build(args.android_dir)
    except (OSError, ValueError) as error:
        print("Android build configuration failed: " + str(error), file=sys.stderr)
        return 1

    if changed:
        print("Configured StashHive Android baseline in: " + ", ".join(changed))
    else:
        print("StashHive Android build configuration is already current.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
