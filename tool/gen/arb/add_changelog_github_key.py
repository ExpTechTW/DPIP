#!/usr/bin/env python3
"""Insert the `changelogOpenOnGitHub` key after each file's changelogBodyEmpty
line. Idempotent. Run from repo root, then gen-l10n.
"""

import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

KEYS = {
    "zh_TW": "\u5728 GitHub \u67e5\u770b",
    "zh": "\u5728 GitHub \u67e5\u770b",
    "zh_Hant_HK": "\u5728 GitHub \u67e5\u770b",
    "zh_Hans": "\u5728 GitHub \u67e5\u770b",
    "en": "View on GitHub",
    "ja": "GitHub \u3067\u898b\u308b",
    "ko": "GitHub\uc5d0\uc11c \ubcf4\uae30",
    "th": "\u0e14\u0e39\u0e1a\u0e19 GitHub",
    "vi": "Xem tr\u00ean GitHub",
    "id": "Lihat di GitHub",
    "fil": "Tingnan sa GitHub",
}


def main() -> None:
    for path in sorted((ROOT / "lib/l10n").glob("app_*.arb")):
        loc = path.stem[len("app_") :]
        original = path.read_text()
        if '"changelogOpenOnGitHub"' in original:
            print(f"{path.name}: already has key, skipped")
            continue
        needle = f'  "changelogBodyEmpty":'
        idx = original.find(needle)
        if idx < 0:
            print(f"{path.name}: no changelogBodyEmpty anchor, SKIPPED")
            continue
        line_end = original.index("\n", idx)
        line = original[idx:line_end]
        if not line.rstrip().endswith(","):
            original = original[:line_end] + "," + original[line_end:]
            line_end = original.index("\n", idx)
        insert = f'  "changelogOpenOnGitHub": "{KEYS[loc]}",'
        original = original[: line_end + 1] + insert + "\n" + original[line_end + 1 :]
        path.write_text(original)
        print(f"{path.name}: +changelogOpenOnGitHub")


if __name__ == "__main__":
    main()