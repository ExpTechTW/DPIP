#!/usr/bin/env python3
"""Insert the More-page beta/partner keys after each locale's
`"moreSectionApp"` line. Idempotent. Run from repo root, then gen-l10n.
"""

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

# key -> per-locale value; locale key is the ARB file's locale code
KEYS = {
    "moreSectionBeta": {
        "zh_TW": "\u6e2c\u8a66\u7248", "zh_Hant_HK": "\u6e2c\u8a66\u7248",
        "zh": "\u6e2c\u8a66\u7248", "zh_Hans": "\u6d4b\u8bd5\u7248",
        "en": "Beta", "ko": "\ud14c\uc2a4\ud2b8 \ubc84\uc804", "ja": "\u30c6\u30b9\u30c8\u7248",
        "vi": "B\u1ea3n th\u1eed nghi\u1ec7m", "id": "Versi uji",
        "th": "\u0e40\u0e27\u0e2d\u0e23\u0e4c\u0e0a\u0e31\u0e19\u0e17\u0e14\u0e2a\u0e2d\u0e1a",
        "fil": "Bersyon ng pagsubok",
    },
    "moreAndroidBeta": {
        "zh_TW": "Android \u6e2c\u8a66\u7248", "zh_Hant_HK": "Android \u6e2c\u8a66\u7248",
        "zh": "Android \u6e2c\u8a66\u7248", "zh_Hans": "Android \u6d4b\u8bd5\u7248",
        "en": "Android beta", "ko": "Android \ud14c\uc2a4\ud2b8 \ubc84\uc804",
        "ja": "Android \u30c6\u30b9\u30c8\u7248", "vi": "B\u1ea3n th\u1eed nghi\u1ec7m Android",
        "id": "Versi uji Android", "th": "\u0e40\u0e27\u0e2d\u0e23\u0e4c\u0e0a\u0e31\u0e19\u0e17\u0e14\u0e2d\u0e1a Android",
        "fil": "Bersyon ng pagsubok sa Android",
    },
    "moreTestFlight": {
        "zh_TW": "iOS \u6e2c\u8a66\u7248\uff08TestFlight\uff09", "zh_Hant_HK": "iOS \u6e2c\u8a66\u7248\uff08TestFlight\uff09",
        "zh": "iOS \u6e2c\u8a66\u7248\uff08TestFlight\uff09", "zh_Hans": "iOS \u6d4b\u8bd5\u7248\uff08TestFlight\uff09",
        "en": "iOS beta (TestFlight)", "ko": "iOS \ud14c\uc2a4\ud2b8 \ubc84\uc804 (TestFlight)",
        "ja": "iOS \u30c6\u30b9\u30c8\u7248\uff08TestFlight\uff09",
        "vi": "B\u1ea3n th\u1eed nghi\u1ec7m iOS (TestFlight)", "id": "Versi uji iOS (TestFlight)",
        "th": "\u0e40\u0e27\u0e2d\u0e23\u0e4c\u0e0a\u0e31\u0e19\u0e17\u0e14\u0e2d\u0e1a iOS (TestFlight)",
        "fil": "Bersyon ng pagsubok sa iOS (TestFlight)",
    },
    "moreSectionPartners": {
        "zh_TW": "\u5408\u4f5c\u5925\u4f34", "zh_Hant_HK": "\u5408\u4f5c\u5925\u4f34",
        "zh": "\u5408\u4f5c\u5925\u4f34", "zh_Hans": "\u5408\u4f5c\u4f19\u4f34",
        "en": "Partners", "ko": "\ud30c\ud2b8\ub108", "ja": "\u30d1\u30fc\u30c8\u30ca\u30fc",
        "vi": "\u0110\u1ed1i t\u00e1c", "id": "Mitra", "th": "\u0e1e\u0e31\u0e19\u0e18\u0e21\u0e34\u0e15\u0e23",
        "fil": "Mga kasosyo",
    },
    "morePartnerGeoscience": {
        "zh_TW": "\u5de8\u79d1\u8cc7\u8a0a\u6709\u9650\u516c\u53f8", "zh_Hant_HK": "\u5de8\u79d1\u8cc7\u8a0a\u6709\u9650\u516c\u53f8",
        "zh": "\u5de8\u79d1\u8cc7\u8a0a\u6709\u9650\u516c\u53f8", "zh_Hans": "\u5de8\u79d1\u8d44\u8baf\u6709\u9650\u516c\u53f8",
        "en": "Geoscience", "ko": "Geoscience", "ja": "Geoscience", "vi": "Geoscience",
        "id": "Geoscience", "th": "Geoscience", "fil": "Geoscience",
    },
    "morePartnerTwds": {
        "zh_TW": "\u53f0\u7063\u6578\u4f4d\u4e32\u6d41\u6709\u9650\u516c\u53f8", "zh_Hant_HK": "\u53f0\u7063\u6578\u4f4d\u4e32\u6d41\u6709\u9650\u516c\u53f8",
        "zh": "\u53f0\u7063\u6578\u4f4d\u4e32\u6d41\u6709\u9650\u516c\u53f8", "zh_Hans": "\u53f0\u6e7e\u6570\u4f4d\u4e32\u6d41\u6709\u9650\u516c\u53f8",
        "en": "TWDS", "ko": "TWDS", "ja": "TWDS", "vi": "TWDS", "id": "TWDS", "th": "TWDS",
        "fil": "TWDS",
    },
}

def locale_of(path: pathlib.Path) -> str:
    return path.stem[len("app_") :]

def insert_after_app(data: str, lines: list[str]) -> str:
    """Insert `lines` after the first '"moreSectionApp"' line."""
    idx = re.search(r'^  "moreSectionApp": ".*?",?$', data, re.M).start()
    line_end = data.index("\n", idx)
    # Re-add the trailing comma to the anchor if it was the last key in the file
    anchor = data[idx : line_end]
    if not anchor.rstrip().endswith(","):
        data = data[:line_end] + "," + data[line_end:]
    new_block = "\n" + "\n".join("  " + ln for ln in lines)
    return data[: line_end + 1] + new_block + "\n" + data[line_end + 1 :]

def main() -> None:
    for path in sorted((ROOT / "lib/l10n").glob("app_*.arb")):
        loc = locale_of(path)
        original = path.read_text()
        if f'"moreSectionBeta"' in original:
            print(f"{path.name}: already has keys, skipped")
            continue
        lines = []
        for key, per_locale in KEYS.items():
            lines.append(f'"{key}": "{per_locale[loc]}",')
        path.write_text(insert_after_app(original, lines))
        print(f"{path.name}: +{len(lines)} keys after moreSectionApp")

if __name__ == "__main__":
    main()