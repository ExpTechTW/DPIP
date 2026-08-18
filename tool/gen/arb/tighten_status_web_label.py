#!/usr/bin/env python3
"""Tighten the server-status page's web-dashboard button to just its name.

The full-width card is the entry to the web dashboard; its title reads the
same as the page's own name instead of a wordy prompt. The subtitle still
shows the host so the row stays a link, not a duplicate header.
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"

LOCALES = {
    "zh": "伺服器狀態",
    "zh_TW": "伺服器狀態",
    "zh_Hant_HK": "伺服器狀態",
    "zh_Hans": "服务器状态",
    "en": "Server status",
    "ja": "サーバー状態",
    "ko": "서버 상태",
    "th": "สถานะเซิร์ฟเวอร์",
    "vi": "Trạng thái máy chủ",
    "id": "Status server",
    "fil": "Katayuan ng server",
}


def main() -> None:
    for path in sorted(ARB_DIR.glob("app_*.arb")):
        locale = path.stem.removeprefix("app_")
        label = LOCALES.get(locale)
        if label is None:
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        if "serverStatusWeb" not in data:
            print(f"skip {path.name} (missing key)")
            continue
        data["serverStatusWeb"] = label
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()