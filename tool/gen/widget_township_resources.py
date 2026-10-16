#!/usr/bin/env python3
"""Generate the native Widget township resources from the Dart assets.

The Dart assets remain the only geographic source of truth. The boundary
payload is gzip-inflated without re-encoding, while the directory is reduced to
the fields the native Widgets need for resolution and weather queries.

Both mobile Widgets consume the same two files: the iOS extension reads them
from its bundle, and the Android Widget reads them from `assets/`. One
generator, so the two platforms cannot disagree about where a township boundary
is — which is the whole reason this is generated rather than copied.

Run:
    python3 tool/gen/widget_township_resources.py
    python3 tool/gen/widget_township_resources.py --check
"""

from __future__ import annotations

import argparse
import gzip
import json
from pathlib import Path
import sys
from typing import Any


REPO = Path(__file__).resolve().parents[2]
DIRECTORY_SOURCE = REPO / "assets/location.json.gz"
BOUNDARY_SOURCE = REPO / "assets/map/town_boundaries.bin.gz"
DIRECTORY_OUTPUT = REPO / "ios/DPIPWidgets/WidgetTownshipDirectory.json"
BOUNDARY_OUTPUT = REPO / "ios/DPIPWidgets/WidgetTownshipBoundaries.bin"
# The Android Widget reads these from its APK's assets. Same bytes, same
# schema; only the destination differs.
ANDROID_DIRECTORY_OUTPUT = (
    REPO / "android/app/src/main/assets/widget_township_directory.json"
)
ANDROID_BOUNDARY_OUTPUT = (
    REPO / "android/app/src/main/assets/widget_township_boundaries.bin"
)
SCHEMA_VERSION = 1


def generated_outputs() -> dict[Path, bytes]:
    with gzip.open(DIRECTORY_SOURCE, "rt", encoding="utf-8") as source:
        source_directory: dict[str, dict[str, Any]] = json.load(source)

    townships = []
    for region_code, town in source_directory.items():
        townships.append(
            {
                "regionCode": region_code,
                "displayName": town["town"] + town["townLevel"],
                "administrativeAreaName": town["city"] + town["cityLevel"],
                "latitude": town["lat"],
                "longitude": town["lng"],
            }
        )

    directory = {
        "schemaVersion": SCHEMA_VERSION,
        "townships": townships,
    }
    directory_bytes = (
        json.dumps(
            directory,
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")
    boundary_bytes = gzip.decompress(BOUNDARY_SOURCE.read_bytes())

    return {
        DIRECTORY_OUTPUT: directory_bytes,
        BOUNDARY_OUTPUT: boundary_bytes,
        ANDROID_DIRECTORY_OUTPUT: directory_bytes,
        ANDROID_BOUNDARY_OUTPUT: boundary_bytes,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="fail when committed outputs differ from a fresh generation",
    )
    args = parser.parse_args()

    outputs = generated_outputs()
    if args.check:
        stale = [
            path
            for path, expected in outputs.items()
            if not path.is_file() or path.read_bytes() != expected
        ]
        if stale:
            for path in stale:
                print(
                    f"stale generated resource: {path.relative_to(REPO)}",
                    file=sys.stderr,
                )
            print(
                "run: python3 tool/gen/widget_township_resources.py",
                file=sys.stderr,
            )
            return 1
        print("Widget township resources are up to date.")
        return 0

    for path, contents in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(contents)
        print(
            f"generated {path.relative_to(REPO)} ({len(contents)} bytes)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
