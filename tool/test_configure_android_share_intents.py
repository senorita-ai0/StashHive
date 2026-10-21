import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from tool.configure_android_share_intents import (
    ANDROID,
    FILTERS,
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
        self.assertEqual(activity.get(ANDROID + "launchMode"), "singleTask")
        filters = activity.findall("intent-filter")
        self.assertEqual(len(filters), len(FILTERS))
        for intent_filter in filters:
            self.assertTrue(intent_filter.findall("action"))
            self.assertTrue(intent_filter.findall("category"))
            self.assertTrue(intent_filter.findall("data"))

    def test_is_idempotent(self):
        first_added = configure_manifest(self.path)
        second_added = configure_manifest(self.path)

        self.assertEqual(first_added, len(FILTERS))
        self.assertEqual(second_added, 0)
        activity = ET.parse(self.path).getroot().find("application/activity")
        self.assertEqual(len(activity.findall("intent-filter")), len(FILTERS))

    def test_fails_clearly_when_main_activity_is_missing(self):
        self.path.write_text(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
            '<application><activity android:name=".OtherActivity" /></application>'
            '</manifest>',
            encoding="utf-8",
        )
        with self.assertRaisesRegex(ValueError, "MainActivity"):
            configure_manifest(self.path)


if __name__ == "__main__":
    unittest.main()
