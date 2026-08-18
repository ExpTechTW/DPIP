#!/usr/bin/env python3
"""Add the EEW-source-filter settings keys to every ARB.

New settings page (More → Display → EEW source): choose whether the live
monitor / replay / earthquake list show every publishing agency's EEW or only
中央氣象署 (CWA). Run from repo root: python3 tool/gen/arb/add_eew_source_keys.py
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent.parent
ARB_DIR = ROOT / "lib" / "l10n"

LOCALES = {
    "zh": {
        "eewSourceSettings": "地震速報來源",
        "eewSourceSubtitle": "選擇要顯示哪些單位發布的地震速報。",
        "eewSourceAll": "所有來源",
        "eewSourceAllDescription": "顯示所有機構發布的地震速報。",
        "eewSourceCwaOnly": "僅中央氣象署",
        "eewSourceCwaOnlyDescription": "只顯示中央氣象署發布的地震速報。",
    },
    "zh_TW": {
        "eewSourceSettings": "地震速報來源",
        "eewSourceSubtitle": "選擇要顯示哪些單位發布的地震速報。",
        "eewSourceAll": "所有來源",
        "eewSourceAllDescription": "顯示所有機構發布的地震速報。",
        "eewSourceCwaOnly": "僅中央氣象署",
        "eewSourceCwaOnlyDescription": "只顯示中央氣象署發布的地震速報。",
    },
    "zh_Hant_HK": {
        "eewSourceSettings": "地震速報來源",
        "eewSourceSubtitle": "選擇要顯示哪些機構發布的地震速報。",
        "eewSourceAll": "所有來源",
        "eewSourceAllDescription": "顯示所有機構發布的地震速報。",
        "eewSourceCwaOnly": "僅中央氣象署",
        "eewSourceCwaOnlyDescription": "只顯示中央氣象署發布的地震速報。",
    },
    "zh_Hans": {
        "eewSourceSettings": "地震速报来源",
        "eewSourceSubtitle": "选择要显示哪些单位发布的地震速报。",
        "eewSourceAll": "所有来源",
        "eewSourceAllDescription": "显示所有机构发布的地震速报。",
        "eewSourceCwaOnly": "仅中央气象署",
        "eewSourceCwaOnlyDescription": "只显示中央气象署发布的地震速报。",
    },
    "en": {
        "eewSourceSettings": "EEW source",
        "eewSourceSubtitle": "Choose which agencies' earthquake early warnings the app shows.",
        "eewSourceAll": "All sources",
        "eewSourceAllDescription": "Show earthquake early warnings from every publishing agency.",
        "eewSourceCwaOnly": "CWA only",
        "eewSourceCwaOnlyDescription": "Show only earthquake early warnings published by Taiwan's Central Weather Administration (CWA).",
    },
    "ja": {
        "eewSourceSettings": "緊急地震速報の情報源",
        "eewSourceSubtitle": "表示する緊急地震速報の発表機関を選択します。",
        "eewSourceAll": "すべての情報源",
        "eewSourceAllDescription": "すべての発表機関の緊急地震速報を表示します。",
        "eewSourceCwaOnly": "中央気象署のみ",
        "eewSourceCwaOnlyDescription": "台湾中央気象署（CWA）が発表した緊急地震速報のみを表示します。",
    },
    "ko": {
        "eewSourceSettings": "지진 조기경보 출처",
        "eewSourceSubtitle": "표시할 지진 조기경보 발표 기관을 선택하세요.",
        "eewSourceAll": "모든 출처",
        "eewSourceAllDescription": "모든 발표 기관의 지진 조기경보를 표시합니다.",
        "eewSourceCwaOnly": "중앙기상서만",
        "eewSourceCwaOnlyDescription": "대만 중앙기상서(CWA)가 발표한 지진 조기경보만 표시합니다.",
    },
    "th": {
        "eewSourceSettings": "แหล่งที่มาของ EEW",
        "eewSourceSubtitle": "เลือกหน่วยงานที่ต้องการแสดงการแจ้งเตือนแผ่นดินไหวล่วงหน้า",
        "eewSourceAll": "ทุกแหล่งที่มา",
        "eewSourceAllDescription": "แสดงการแจ้งเตือนแผ่นดินไหวล่วงหน้าจากทุกหน่วยงานที่เผยแพร่",
        "eewSourceCwaOnly": "เฉพาะ CWA เท่านั้น",
        "eewSourceCwaOnlyDescription": "แสดงเฉพาะการแจ้งเตือนที่เผยแพร่โดยสำนักงานอุตุนิยมวิทยากลางไต้หวัน (CWA) เท่านั้น",
    },
    "vi": {
        "eewSourceSettings": "Nguồn cảnh báo sớm động đất",
        "eewSourceSubtitle": "Chọn cơ quan phát hành cảnh báo sớm động đất muốn hiển thị.",
        "eewSourceAll": "Tất cả nguồn",
        "eewSourceAllDescription": "Hiển thị cảnh báo sớm động đất từ mọi cơ quan phát hành.",
        "eewSourceCwaOnly": "Chỉ CWA",
        "eewSourceCwaOnlyDescription": "Chỉ hiển thị cảnh báo sớm động đất do Cục Khí tượng Trung ương Đài Loan (CWA) phát hành.",
    },
    "id": {
        "eewSourceSettings": "Sumber EEW",
        "eewSourceSubtitle": "Pilih badan penerbit peringatan dini gempa yang ingin ditampilkan.",
        "eewSourceAll": "Semua sumber",
        "eewSourceAllDescription": "Tampilkan peringatan dini gempa dari semua badan penerbit.",
        "eewSourceCwaOnly": "Hanya CWA",
        "eewSourceCwaOnlyDescription": "Hanya tampilkan peringatan dini gempa yang diterbitkan oleh Badan Meteorologi Pusat Taiwan (CWA).",
    },
    "fil": {
        "eewSourceSettings": "Pinagmulan ng EEW",
        "eewSourceSubtitle": "Piliin kung aling mga ahensya ang ipapakitang paunang babala sa lindol.",
        "eewSourceAll": "Lahat ng pinagmulan",
        "eewSourceAllDescription": "Ipakita ang paunang babala sa lindol mula sa bawat ahensyang naglalabas nito.",
        "eewSourceCwaOnly": "CWA lang",
        "eewSourceCwaOnlyDescription": "Ipakita lamang ang paunang babala sa lindol na inilabas ng Central Weather Administration (CWA) ng Taiwan.",
    },
}

# Where to insert the new keys so they stay grouped with the other map/default
# settings-page strings.
ANCHOR = "defaultMapLayerSettings"


def main() -> None:
    for path in sorted(ARB_DIR.glob("app_*.arb")):
        locale = path.stem.removeprefix("app_")
        if locale not in LOCALES:
            print(f"skip {path.name} (no translations)")
            continue
        updates = LOCALES[locale]
        data = json.loads(path.read_text(encoding="utf-8"))
        out = {}
        for key, value in data.items():
            out[key] = value
            if key == ANCHOR:
                for k, v in updates.items():
                    out[k] = v
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()
