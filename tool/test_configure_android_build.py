import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from tool.configure_android_build import (
    ANDROID_PLUGIN_VERSION,
    BUILD_TOOLS_VERSION,
    COMPILE_SDK,
    GRADLE_VERSION,
    KOTLIN_PLUGIN_VERSION,
    configure_android_build,
)


SETTINGS = """pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
include(":app")
"""
ROOT_BUILD = """allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
"""
APP_BUILD = """plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.example.stashhive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    defaultConfig {
        applicationId = "com.example.stashhive"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
flutter {
    source = "../.."
}
"""
WRAPPER = """distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.13-all.zip
"""
PROPERTIES = "android.useAndroidX=true\n"


class ConfigureAndroidBuildTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.android_dir = Path(self.temporary_directory.name) / "android"
        (self.android_dir / "app").mkdir(parents=True)
        (self.android_dir / "gradle" / "wrapper").mkdir(parents=True)
        files = {
            "settings.gradle.kts": SETTINGS,
            "build.gradle.kts": ROOT_BUILD,
            "app/build.gradle.kts": APP_BUILD,
            "gradle/wrapper/gradle-wrapper.properties": WRAPPER,
            "gradle.properties": PROPERTIES,
        }
        for relative_path, content in files.items():
            (self.android_dir / relative_path).write_text(content, encoding="utf-8")

    def tearDown(self):
        self.temporary_directory.cleanup()

    def test_aligns_flutter_android_versions_and_sdk_settings(self):
        changed = configure_android_build(self.android_dir)
        self.assertEqual(len(changed), 10)

        settings = (self.android_dir / "settings.gradle.kts").read_text(encoding="utf-8")
        self.assertIn(f'id("com.android.application") version "{ANDROID_PLUGIN_VERSION}" apply false', settings)
        self.assertIn(f'id("org.jetbrains.kotlin.android") version "{KOTLIN_PLUGIN_VERSION}" apply false', settings)

        wrapper = (self.android_dir / "gradle/wrapper/gradle-wrapper.properties").read_text(encoding="utf-8")
        self.assertIn(f"gradle-{GRADLE_VERSION}-all.zip", wrapper)

        properties = (self.android_dir / "gradle.properties").read_text(encoding="utf-8")
        for expected in (
            "android.newDsl=false",
            "android.builtInKotlin=true",
            "kotlin.incremental=false",
            "kotlin.incremental.useClasspathSnapshot=false",
            "kotlin.daemon.enabled=true",
        ):
            self.assertIn(expected, properties)

        app = (self.android_dir / "app/build.gradle.kts").read_text(encoding="utf-8")
        self.assertIn(f"compileSdk = {COMPILE_SDK}", app)
        self.assertIn("sourceCompatibility = JavaVersion.VERSION_17", app)
        self.assertIn("targetCompatibility = JavaVersion.VERSION_17", app)
        self.assertIn("JvmTarget.JVM_17", app)
        self.assertNotIn(
            'id("org.jetbrains.kotlin.android")',
            app,
            "AGP built-in Kotlin must not be applied alongside the legacy Kotlin plugin.",
        )

        root = (self.android_dir / "build.gradle.kts").read_text(encoding="utf-8")
        self.assertEqual(root.count("STASHHIVE_SHARED_ANDROID_SDK_CONFIGURATION"), 1)
        self.assertIn(f'buildToolsVersion = "{BUILD_TOOLS_VERSION}"', root)

        resources = [
            "app/src/main/res/values/stashhive_colors.xml",
            "app/src/main/res/drawable/stashhive_launcher_foreground.xml",
            "app/src/main/res/drawable/stashhive_launcher_legacy.xml",
            "app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
            "app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml",
        ]
        for relative in resources:
            resource_path = self.android_dir / relative
            self.assertTrue(resource_path.is_file(), relative)
            root_tag = ET.parse(resource_path).getroot().tag.rsplit("}", 1)[-1]
            self.assertIn(
                root_tag,
                {"resources", "vector", "layer-list", "adaptive-icon"},
                relative,
            )
        self.assertIn(
            "@drawable/stashhive_launcher_foreground",
            (self.android_dir / resources[2]).read_text(encoding="utf-8"),
        )
        foreground = (self.android_dir / resources[1]).read_text(encoding="utf-8")
        self.assertNotIn(
            "transform=",
            foreground,
            "Android VectorDrawable paths should use explicit coordinates, not SVG transforms.",
        )
        self.assertIn(
            'android:pathData="M54,21 L67,28.5 L67,43.5 L54,51',
            foreground,
            "The top hive cell should remain inside the adaptive-icon safe zone.",
        )

    def test_removes_short_legacy_kotlin_plugin_alias(self):
        app_path = self.android_dir / "app" / "build.gradle.kts"
        app_text = app_path.read_text(encoding="utf-8")
        app_text = app_text.replace(
            'id("org.jetbrains.kotlin.android")',
            'id("kotlin-android")',
        )
        app_path.write_text(app_text, encoding="utf-8")

        configure_android_build(self.android_dir)

        configured = app_path.read_text(encoding="utf-8")
        self.assertNotIn('id("org.jetbrains.kotlin.android")', configured)
        self.assertNotIn('id("kotlin-android")', configured)
        self.assertIn("JvmTarget.JVM_17", configured)

    def test_configuration_is_idempotent(self):
        configure_android_build(self.android_dir)
        self.assertEqual(configure_android_build(self.android_dir), [])
        root = (self.android_dir / "build.gradle.kts").read_text(encoding="utf-8")
        self.assertEqual(root.count("STASHHIVE_SHARED_ANDROID_SDK_CONFIGURATION"), 1)

    def test_missing_generated_android_files_fail_clearly(self):
        with self.assertRaisesRegex(FileNotFoundError, "Generated Android runner is incomplete"):
            configure_android_build(self.android_dir / "missing")


if __name__ == "__main__":
    unittest.main()
