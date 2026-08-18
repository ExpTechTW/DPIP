#!/usr/bin/env python3
"""Insert the partners-note key after each locale's `"moreSectionPartners"`
line. Idempotent. Run from repo root, then gen-l10n.
"""

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

NOTES = {
    "zh_TW": "\u4f9d\u6642\u9593\u5408\u4f5c\u79a9\u5e8f\u4f86\u6392\u5217\u3002\u611f\u8b1d\u9019\u4e9b\u500b\u4eba\u8207\u516c\u53f8\u5c0d\u9632\u707d\u4e8b\u696d\u7684\u8ca2\u737b\uff0c\u4ed6\u5011\u7684\u4ed8\u51fa\u8b93 DPIP \u8b8a\u5f97\u53ef\u80fd\u3002",
    "zh_Hant_HK": "\u4f9d\u6642\u9593\u5408\u4f5c\u79a9\u5e8f\u4f86\u6392\u5217\u3002\u611f\u8b1d\u9019\u4e9b\u500b\u4eba\u8207\u516c\u53f8\u5c0d\u9632\u707d\u4e8b\u696d\u7684\u8ca2\u737b\uff0c\u4ed6\u5011\u7684\u4ed8\u51fa\u8b93 DPIP \u8b8a\u5f97\u53ef\u80fd\u3002",
    "zh": "\u4f9d\u6642\u9593\u5408\u4f5c\u79a9\u5e8f\u4f86\u6392\u5217\u3002\u611f\u8b1d\u9019\u4e9b\u500b\u4eba\u8207\u516c\u53f8\u5c0d\u9632\u707d\u4e8b\u696d\u7684\u8ca2\u737b\uff0c\u4ed6\u5011\u7684\u4ed8\u51fa\u8b93 DPIP \u8b8a\u5f97\u53ef\u80fd\u3002",
    "zh_Hans": "\u6309\u65f6\u95f4\u5408\u4f5c\u79e9\u5e8f\u6392\u5217\u3002\u611f\u8c22\u8fd9\u4e9b\u4e2a\u4eba\u4e0e\u516c\u53f8\u5bf9\u9632\u707e\u4e8b\u4e1a\u7684\u8d21\u732e\uff0c\u4ed6\u4eec\u7684\u4ed8\u51fa\u8ba9 DPIP \u53d8\u5f97\u53ef\u80fd\u3002",
    "en": "Listed in order of partnership. Thank you to the individuals and companies whose contributions to disaster preparedness made DPIP possible.",
    "ko": "\ud30c\ud2b8\ub108\uc2ed \uc21c\uc11c\ub300\ub85c \ud45c\uc2dc\ub429\ub2c8\ub2e4. \uc7ac\ub09c \uc608\ubc29\uc5d0 \uae30\uc5ec\ud55c \uac1c\uc778\uacfc \uae30\uc5c5\uc5d0 \uac10\uc0ac\ub4dc\ub9bd\ub2c8\ub2e4. \uadf8\ub4e4\uc758 \uae30\uc5ec \ub354\ubd09\uc5d0 DPIP\uac00 \uac00\ub2a5\ud588\uc2b5\ub2c8\ub2e4.",
    "ja": "\u63d0\u643a\u9806\u306b\u8868\u793a\u3057\u3066\u3044\u307e\u3059\u3002\u9632\u707d\u3078\u306e\u8ca2\u732e\u3067 DPIP \u3092\u652f\u3048\u3066\u304f\u3060\u3055\u3063\u305f\u500b\u4eba\u30fb\u4f01\u696d\u306e\u7686\u69d8\u306b\u611f\u8b1d\u3057\u307e\u3059\u3002",
    "vi": "Theo th\u1ee9 t\u1ef1 h\u1ee3p t\u00e1c. Xin c\u1ea3m \u01a1n c\u00e1c c\u00e1 nh\u00e2n v\u00e0 c\u00f4ng ty \u0111\u00e3 \u0111\u00f3ng g\u00f3p cho c\u00f4ng t\u00e1c ph\u00f2ng ch\u1ed1ng thi\u00ean tai, nh\u1edd \u0111\u00f3 DPIP m\u1edbi c\u00f3 th\u1ec3 ra \u0111\u1eddi.",
    "id": "Urut sesuai waktu kemitraan. Terima kasih kepada para individu dan perusahaan yang berkontribusi pada penanggulangan bencana; kontribusi mereka membuat DPIP menjadi mungkin.",
    "th": "\u0e40\u0e23\u0e35\u0e22\u0e07\u0e15\u0e32\u0e21\u0e25\u0e33\u0e14\u0e31\u0e1a\u0e04\u0e39\u0e48\u0e04\u0e27\u0e32\u0e21\u0e23\u0e48\u0e27\u0e21\u0e21\u0e37\u0e2d \u0e02\u0e2d\u0e1a\u0e04\u0e38\u0e13\u0e1a\u0e38\u0e04\u0e04\u0e25\u0e41\u0e25\u0e30\u0e1a\u0e23\u0e34\u0e29\u0e31\u0e17\u0e17\u0e35\u0e48\u0e21\u0e35\u0e2a\u0e48\u0e27\u0e19\u0e23\u0e48\u0e27\u0e21\u0e43\u0e19\u0e01\u0e32\u0e23\u0e1b\u0e49\u0e2d\u0e07\u0e01\u0e31\u0e19\u0e20\u0e31\u0e22\u0e1e\u0e34\u0e1a\u0e31\u0e15\u0e34 \u0e01\u0e32\u0e23\u0e2a\u0e19\u0e31\u0e1a\u0e2a\u0e19\u0e38\u0e19\u0e02\u0e2d\u0e07\u0e1e\u0e27\u0e01\u0e40\u0e02\u0e32\u0e17\u0e33\u0e43\u0e2b\u0e49 DPIP \u0e40\u0e01\u0e34\u0e14\u0e02\u0e36\u0e49\u0e19\u0e44\u0e14\u0e49",
    "fil": "Nakaayos ayon sa tamang panahon ng pakikipagtulungan. Salamat sa mga indibidwal at kompanyang nag-ambag sa paghahanda sa kalamidad; ang kanilang kontribusyon ang nagbigay-daan sa DPIP.",
}

def locale_of(path: pathlib.Path) -> str:
    return path.stem[len("app_") :]

def main() -> None:
    for path in sorted((ROOT / "lib/l10n").glob("app_*.arb")):
        loc = locale_of(path)
        original = path.read_text()
        if '"morePartnersNote"' in original:
            print(f"{path.name}: already has key, skipped")
            continue
        anchor = re.search(r'^  "moreSectionPartners": ".*?",?$', original, re.M)
        if anchor is None:
            print(f"{path.name}: no moreSectionPartners anchor, SKIPPED")
            continue
        line_end = original.index("\n", anchor.start())
        anchor_line = original[anchor.start() : line_end]
        if not anchor_line.rstrip().endswith(","):
            original = original[:line_end] + "," + original[line_end:]
        line_end = original.index("\n", anchor.start())
        insert = f'  "morePartnersNote": "{NOTES[loc]}",'
        original = original[: line_end + 1] + insert + "\n" + original[line_end + 1 :]
        path.write_text(original)
        print(f"{path.name}: +morePartnersNote")

if __name__ == "__main__":
    main()