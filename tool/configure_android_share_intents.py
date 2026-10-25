#!/usr/bin/env python3
"""Idempotently set the StashHive app label and add incoming-share filters to a generated Android runner."""

from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ANDROID_NS = "http://schemas.android.com/apk/res/android"
TOOLS_NS = "http://schemas.android.com/tools"
ANDROID = "{" + ANDROID_NS + "}"
DEFAULT_CATEGORY = "android.intent.category.DEFAULT"
SEND = "android.intent.action.SEND"
SEND_MULTIPLE = "android.intent.action.SEND_MULTIPLE"

ET.register_namespace("android", ANDROID_NS)
ET.register_namespace("tools", TOOLS_NS)

# Advertise supported types directly plus */* for mixed batches; the receiver validates each item.
FILTERS = (
    (SEND, "text/*"),
    (SEND, "text/uri-list"),
    (SEND, "image/*"),
    (SEND, "application/pdf"),
    (SEND, "application/msword"),
    (
        SEND,
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ),
    (SEND, "application/rtf"),
    (SEND, "text/csv"),
    # Multiple selection is exposed for every supported media family, not
    # only images, so homogeneous document/text batches can reach sequential
    # Quick Save review too.
    (SEND_MULTIPLE, "text/*"),
    (SEND_MULTIPLE, "text/uri-list"),
    (SEND_MULTIPLE, "image/*"),
    (SEND_MULTIPLE, "application/pdf"),
    (SEND_MULTIPLE, "application/msword"),
    (
        SEND_MULTIPLE,
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ),
    (SEND_MULTIPLE, "application/rtf"),
    (SEND_MULTIPLE, "text/csv"),
    # Android commonly uses */* when a batch contains mixed MIME types.
    (SEND_MULTIPLE, "*/*"),
)


def _has_filter(activity: ET.Element, action: str, mime_type: str) -> bool:
    for intent_filter in activity.findall("intent-filter"):
        actions = {
            element.get(ANDROID + "name")
            for element in intent_filter.findall("action")
        }
        categories = {
            element.get(ANDROID + "name")
            for element in intent_filter.findall("category")
        }
        mime_types = {
            element.get(ANDROID + "mimeType")
            for element in intent_filter.findall("data")
        }
        if (
            action in actions
            and DEFAULT_CATEGORY in categories
            and mime_type in mime_types
        ):
            return True
    return False


def configure_manifest(manifest_path: str | Path) -> int:
    """Patch a generated manifest and return the number of filters added."""
    path = Path(manifest_path)
    if not path.is_file():
        raise FileNotFoundError(
            f"Android manifest not found: {path}. Generate Flutter's Android runner first."
        )

    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
    tree = ET.parse(path, parser=parser)
    root = tree.getroot()
    application = root.find("application")
    if application is None:
        raise ValueError("AndroidManifest.xml has no <application> element.")

    # Keep generated native runners aligned with the user-facing product name.
    application.set(ANDROID + "label", "StashHive")

    activities = application.findall("activity")
    main_activity = next(
        (
            item
            for item in activities
            if (item.get(ANDROID + "name") or "").rsplit(".", 1)[-1]
            == "MainActivity"
        ),
        None,
    )
    if main_activity is None:
        raise ValueError(
            "Could not find the Flutter .MainActivity in AndroidManifest.xml."
        )

    main_activity.set(ANDROID + "launchMode", "singleTask")
    added = 0
    for action, mime_type in FILTERS:
        if _has_filter(main_activity, action, mime_type):
            continue
        intent_filter = ET.SubElement(main_activity, "intent-filter")
        ET.SubElement(intent_filter, "action", {ANDROID + "name": action})
        ET.SubElement(
            intent_filter,
            "category",
            {ANDROID + "name": DEFAULT_CATEGORY},
        )
        ET.SubElement(intent_filter, "data", {ANDROID + "mimeType": mime_type})
        added += 1

    ET.indent(tree, space="    ")
    tree.write(path, encoding="utf-8", xml_declaration=True)
    return added


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        default="android/app/src/main/AndroidManifest.xml",
        help="Android manifest path (defaults to the generated Flutter runner).",
    )
    args = parser.parse_args()
    try:
        added = configure_manifest(args.manifest)
    except (OSError, ET.ParseError, ValueError) as error:
        print("Android share configuration failed: " + str(error), file=sys.stderr)
        return 1
    print(
        "Android share configuration complete; added "
        + str(added)
        + " intent filter(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
