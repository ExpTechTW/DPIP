#!/usr/bin/env python3
"""Insert the version-highlights l10n keys after the moreVersionNotes block in
every ARB. Idempotent. Run from repo root, then gen-l10n.

The keys cover only the *chrome* of the version-highlights page — the card
body content itself ships as structured JSON (see 26.1/), so it is not part
of the ARB parity contract.
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[3]
ARB_DIR = ROOT / "lib" / "l10n"

# locale -> {key: value}. Present keys are skipped per-file.
NEW_KEYS = {
    "zh": {
        "releaseHighlightsTitle": "本次更新",
        "releaseHighlightsTabNormal": "做了哪些改變",
        "releaseHighlightsTabAdvanced": "深入技術",
        "releaseHighlightsEmpty": "目前沒有內容。",
        "releaseHighlightsSeeNotes": "查看完整更新日誌",
        "highlightCardTechnical": "技術細節",
    },
    "zh_TW": {
        "releaseHighlightsTitle": "本次更新",
        "releaseHighlightsTabNormal": "做了哪些改變",
        "releaseHighlightsTabAdvanced": "深入技術",
        "releaseHighlightsEmpty": "目前沒有內容。",
        "releaseHighlightsSeeNotes": "查看完整更新日誌",
        "highlightCardTechnical": "技術細節",
    },
    "zh_Hant_HK": {
        "releaseHighlightsTitle": "本次更新",
        "releaseHighlightsTabNormal": "做了哪些改變",
        "releaseHighlightsTabAdvanced": "深入技術",
        "releaseHighlightsEmpty": "目前沒有內容。",
        "releaseHighlightsSeeNotes": "查看完整更新日誌",
        "highlightCardTechnical": "技術細節",
    },
    "zh_Hans": {
        "releaseHighlightsTitle": "本次更新",
        "releaseHighlightsTabNormal": "做了哪些改变",
        "releaseHighlightsTabAdvanced": "深入技术",
        "releaseHighlightsEmpty": "目前没有内容。",
        "releaseHighlightsSeeNotes": "查看完整更新日志",
        "highlightCardTechnical": "技术细节",
    },
    "en": {
        "releaseHighlightsTitle": "What changed in this release",
        "releaseHighlightsTabNormal": "For users",
        "releaseHighlightsTabAdvanced": "Deep dive",
        "releaseHighlightsEmpty": "Nothing here yet.",
        "releaseHighlightsSeeNotes": "Full release notes",
        "highlightCardTechnical": "Technical",
    },
    "ja": {
        "releaseHighlightsTitle": "今回の更新",
        "releaseHighlightsTabNormal": "変更点",
        "releaseHighlightsTabAdvanced": "技術詳細",
        "releaseHighlightsEmpty": "まだコンテンツがありません。",
        "releaseHighlightsSeeNotes": "完全なリリースノート",
        "highlightCardTechnical": "技術詳細",
    },
    "ko": {
        "releaseHighlightsTitle": "이번 업데이트",
        "releaseHighlightsTabNormal": "변경된 점",
        "releaseHighlightsTabAdvanced": "기술 세부",
        "releaseHighlightsEmpty": "아직 내용이 없습니다.",
        "releaseHighlightsSeeNotes": "전체 릴리스 노트",
        "highlightCardTechnical": "기술 세부",
    },
    "th": {
        "releaseHighlightsTitle": "สิ่งที่เปลี่ยนแปลง",
        "releaseHighlightsTabNormal": "สำหรับผู้ใช้",
        "releaseHighlightsTabAdvanced": "เจาะลึก",
        "releaseHighlightsEmpty": "ยังไม่มีเนื้อหา",
        "releaseHighlightsSeeNotes": "ดูบันทึกทั้งหมด",
        "highlightCardTechnical": "เทคนิค",
    },
    "vi": {
        "releaseHighlightsTitle": "Thay đổi trong bản này",
        "releaseHighlightsTabNormal": "Cho người dùng",
        "releaseHighlightsTabAdvanced": "Đi sâu",
        "releaseHighlightsEmpty": "Chưa có nội dung.",
        "releaseHighlightsSeeNotes": "Xem ghi chú đầy đủ",
        "highlightCardTechnical": "Kỹ thuật",
    },
    "id": {
        "releaseHighlightsTitle": "Yang berubah",
        "releaseHighlightsTabNormal": "Untuk pengguna",
        "releaseHighlightsTabAdvanced": "Mendalam",
        "releaseHighlightsEmpty": "Belum ada konten.",
        "releaseHighlightsSeeNotes": "Catatan rilis lengkap",
        "highlightCardTechnical": "Teknis",
    },
    "fil": {
        "releaseHighlightsTitle": "Ano ang nagbago",
        "releaseHighlightsTabNormal": "Para sa mga user",
        "releaseHighlightsTabAdvanced": "Mas malalim",
        "releaseHighlightsEmpty": "Wala pang laman.",
        "releaseHighlightsSeeNotes": "Buong tala ng release",
        "highlightCardTechnical": "Teknikal",
    },
}


def main() -> None:
    for path in sorted(ARB_DIR.glob("app_*.arb")):
        locale = path.stem.removeprefix("app_")
        insert = NEW_KEYS.get(locale)
        if insert is None:
            print(f"skip {path.name} (no translations)")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        missing = {k: v for k, v in insert.items() if k not in data}
        if not missing:
            print(f"skip {path.name} (all keys present)")
            continue
        out = {}
        for key, value in data.items():
            out[key] = value
            if key == "moreVersionNotes":
                for nk, nv in missing.items():
                    out[nk] = nv
        for nk, nv in missing.items():
            if nk not in out:
                out[nk] = nv
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()