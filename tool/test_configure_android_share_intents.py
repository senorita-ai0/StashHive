import tempfile
import unittest
import xml.etree.ElementTree as ET
from unittest.mock import patch
from pathlib import Path

from tool.configure_android_share_intents import (
    ANDROID,
    FILTERS,
    SEND,
    SEND_MULTIPLE,
    configure_manifest,
)


MANIFEST = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="app.stashhive">
    <application android:label="StashHive">
        <activity android:name=".MainActivity" android:exported="true" />
    </application>
</manifest>
"""


class ConfigureAndroidShareIntentsTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary_directory.name) / "AndroidManifest.xml"
        self.path.write_text(MANIFEST, encoding="utf-8")

    def tearDown(self):
        self.temporary_directory.cleanup()

    def test_adds_expected_share_filters_and_single_task_launch_mode(self):
        added = configure_manifest(self.path)
        root = ET.parse(self.path).getroot()
        activity = root.find("application/activity")

        self.assertEqual(added, len(FILTERS))
        application = root.find("application")
        self.assertEqual(application.get(ANDROID + "label"), "StashHive")
        self.assertEqual(application.get(ANDROID + "icon"), "@mipmap/ic_launcher")
        self.assertEqual(application.get(ANDROID + "roundIcon"), "@mipmap/ic_launcher")
        self.assertEqual(activity.get(ANDROID + "launchMode"), "singleTask")
        filters = activity.findall("intent-filter")
        self.assertEqual(len(filters), len(FILTERS))
        actual_pairs = set()
        for intent_filter in filters:
            actions = intent_filter.findall("action")
            categories = intent_filter.findall("category")
            data_elements = intent_filter.findall("data")
            self.assertEqual(len(actions), 1)
            self.assertEqual(len(categories), 1)
            self.assertEqual(len(data_elements), 1)
            actual_pairs.add(
                (actions[0].get(ANDROID + "name"),
                 data_elements[0].get(ANDROID + "mimeType"))
            )

        self.assertEqual(actual_pairs, set(FILTERS))
        single_types = {mime for action, mime in actual_pairs if action == SEND}
        multiple_types = {
            mime for action, mime in actual_pairs if action == SEND_MULTIPLE
        }
        self.assertTrue(
            single_types.issubset(multiple_types),
            "All supported single-share MIME families must also support multi-select.",
        )
        self.assertIn(
            "*/*",
            multiple_types,
            "Mixed-MIME ACTION_SEND_MULTIPLE batches use the wildcard MIME type.",
        )

    def test_is_idempotent(self):
        first_added = configure_manifest(self.path)
        second_added = configure_manifest(self.path)

        self.assertEqual(first_added, len(FILTERS))
        self.assertEqual(second_added, 0)
        activity = ET.parse(self.path).getroot().find("application/activity")
        self.assertEqual(len(activity.findall("intent-filter")), len(FILTERS))
        application = ET.parse(self.path).getroot().find("application")
        self.assertEqual(application.get(ANDROID + "label"), "StashHive")
        self.assertEqual(application.get(ANDROID + "icon"), "@mipmap/ic_launcher")
        self.assertEqual(application.get(ANDROID + "roundIcon"), "@mipmap/ic_launcher_round")

    def test_fails_clearly_when_main_activity_is_missing_without_rewriting_file(self):
        invalid_manifest = (
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
            '<application><activity android:name=".OtherActivity" /></application>'
            '</manifest>'
        )
        self.path.write_text(invalid_manifest, encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "MainActivity"):
            configure_manifest(self.path)

        self.assertEqual(self.path.read_text(encoding="utf-8"), invalid_manifest)

    def test_fails_clearly_when_application_is_missing(self):
        self.path.write_text("<manifest />", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "<application>"):
            configure_manifest(self.path)

    def test_fails_clearly_when_manifest_is_missing(self):
        missing_path = self.path.parent / "missing" / "AndroidManifest.xml"
        with self.assertRaisesRegex(FileNotFoundError, "Android manifest not found"):
            configure_manifest(missing_path)

    def test_reports_malformed_xml_without_overwriting_it(self):
        malformed_manifest = "<manifest><application>"
        self.path.write_text(malformed_manifest, encoding="utf-8")

        with self.assertRaises(ET.ParseError):
            configure_manifest(self.path)

        self.assertEqual(self.path.read_text(encoding="utf-8"), malformed_manifest)

    def test_failed_atomic_replace_preserves_manifest_and_cleans_temp_file(self):
        original_manifest = self.path.read_text(encoding="utf-8")

        with patch(
            "tool.configure_android_share_intents.os.replace",
            side_effect=OSError("simulated replacement failure"),
        ):
            with self.assertRaisesRegex(OSError, "simulated replacement failure"):
                configure_manifest(self.path)

        self.assertEqual(self.path.read_text(encoding="utf-8"), original_manifest)
        self.assertEqual(
            list(self.path.parent.glob(".AndroidManifest.xml.*.tmp")),
            [],
            "A failed replacement must not leave a temporary manifest behind.",
        )


if __name__ == "__main__":
    unittest.main()
