import tempfile
import unittest
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
        self.assertEqual(len(changed), 5)

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
        self.assertIn(f'buildToolsVersion = "{BUILD_TOOLS_VERSION}"', app)
        self.assertIn("sourceCompatibility = JavaVersion.VERSION_17", app)
        self.assertIn("targetCompatibility = JavaVersion.VERSION_17", app)
        self.assertIn("JvmTarget.JVM_17", app)

        root = (self.android_dir / "build.gradle.kts").read_text(encoding="utf-8")
        self.assertEqual(root.count("STASHHIVE_SHARED_ANDROID_SDK_CONFIGURATION"), 1)
        self.assertIn(f'buildToolsVersion = "{BUILD_TOOLS_VERSION}"', root)

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
