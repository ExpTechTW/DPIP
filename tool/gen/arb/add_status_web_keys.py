#!/usr/bin/env python3
"""Insert the server-status page's new keys in every ARB.

Adds:
  serverStatusWeb      — full-width link to the web dashboard
  serverStatusWebUrl   — subtitle (the web URL)
  endpointTierLbApi / endpointTierCoreApi / endpointTierCoreExclusiveApi /
  endpointTierCoreStatic / endpointTierLegacyApi — tier section headers

Run from repo root: python3 tool/add_status_web_keys.py
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"

LOCALES = {
    "zh": {
        "serverStatusWeb": "在瀏覽器中開啟完整狀態頁",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API（EEW / 強震警報）",
        "endpointTierLbStatic": "LB 靜態資源",
        "endpointTierCoreApi": "Core API（地震報告）",
        "endpointTierCoreStatic": "Core 靜態資源",
        "endpointTierCoreExclusiveApi": "Core 專屬 API（雷達 / 氣象 / 風場）",
        "endpointTierCoreStaticExclusive": "Core 專屬靜態資源",
        "endpointTierLegacyApi": "舊版 API（api-1）",
    },
    "zh_TW": {
        "serverStatusWeb": "在瀏覽器中開啟完整狀態頁",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API（EEW / 強震警報）",
        "endpointTierLbStatic": "LB 靜態資源",
        "endpointTierCoreApi": "Core API（地震報告）",
        "endpointTierCoreStatic": "Core 靜態資源",
        "endpointTierCoreExclusiveApi": "Core 專屬 API（雷達 / 氣象 / 風場）",
        "endpointTierCoreStaticExclusive": "Core 專屬靜態資源",
        "endpointTierLegacyApi": "舊版 API（api-1）",
    },
    "zh_Hant_HK": {
        "serverStatusWeb": "在瀏覽器中開啟完整狀態頁",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API（EEW / 強震警報）",
        "endpointTierLbStatic": "LB 靜態資源",
        "endpointTierCoreApi": "Core API（地震報告）",
        "endpointTierCoreStatic": "Core 靜態資源",
        "endpointTierCoreExclusiveApi": "Core 專屬 API（雷達 / 氣象 / 風場）",
        "endpointTierCoreStaticExclusive": "Core 專屬靜態資源",
        "endpointTierLegacyApi": "舊版 API（api-1）",
    },
    "zh_Hans": {
        "serverStatusWeb": "在浏览器中打开完整状态页",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API（EEW / 强震警报）",
        "endpointTierLbStatic": "LB 静态资源",
        "endpointTierCoreApi": "Core API（地震报告）",
        "endpointTierCoreStatic": "Core 静态资源",
        "endpointTierCoreExclusiveApi": "Core 专属 API（雷达 / 气象 / 风场）",
        "endpointTierCoreStaticExclusive": "Core 专属静态资源",
        "endpointTierLegacyApi": "旧版 API（api-1）",
    },
    "en": {
        "serverStatusWeb": "Open the full status page in your browser",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API (EEW / strong-motion alerts)",
        "endpointTierLbStatic": "LB static",
        "endpointTierCoreApi": "Core API (earthquake reports)",
        "endpointTierCoreStatic": "Core static",
        "endpointTierCoreExclusiveApi": "Core-exclusive API (radar / weather / wind)",
        "endpointTierCoreStaticExclusive": "Core-exclusive static",
        "endpointTierLegacyApi": "Legacy API (api-1)",
    },
    "ja": {
        "serverStatusWeb": "完全なステータスページをブラウザで開く",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API（EEW / 強震警報）",
        "endpointTierLbStatic": "LB 静的リソース",
        "endpointTierCoreApi": "Core API（地震報告）",
        "endpointTierCoreStatic": "Core 静的リソース",
        "endpointTierCoreExclusiveApi": "Core 専用 API（レーダー / 気象 / 風）",
        "endpointTierCoreStaticExclusive": "Core 専用静的リソース",
        "endpointTierLegacyApi": "レガシー API（api-1）",
    },
    "ko": {
        "serverStatusWeb": "브라우저에서 전체 상태 페이지 열기",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API (EEW / 강진 경보)",
        "endpointTierLbStatic": "LB 정적 리소스",
        "endpointTierCoreApi": "Core API (지진 보고)",
        "endpointTierCoreStatic": "Core 정적 리소스",
        "endpointTierCoreExclusiveApi": "Core 전용 API (레이다 / 기상 / 바람)",
        "endpointTierCoreStaticExclusive": "Core 전용 정적 리소스",
        "endpointTierLegacyApi": "레거시 API (api-1)",
    },
    "th": {
        "serverStatusWeb": "เปิดหน้าสถานะเต็มในเบราว์เซอร์",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API (EEW / แจ้งเตือนแผ่นดินไหวรุนแรง)",
        "endpointTierLbStatic": "LB ทรัพยากรคงที่",
        "endpointTierCoreApi": "Core API (รายงานแผ่นดินไหว)",
        "endpointTierCoreStatic": "Core ทรัพยากรคงที่",
        "endpointTierCoreExclusiveApi": "Core เฉพาะ API (เรดาร์ / อากาศ / ลม)",
        "endpointTierCoreStaticExclusive": "Core เฉพาะทรัพยากรคงที่",
        "endpointTierLegacyApi": "API เดิม (api-1)",
    },
    "vi": {
        "serverStatusWeb": "Mở trang trạng thái đầy đủ trong trình duyệt",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API (EEW / cảnh báo rung lắc mạnh)",
        "endpointTierLbStatic": "LB tĩnh",
        "endpointTierCoreApi": "Core API (báo cáo động đất)",
        "endpointTierCoreStatic": "Core tĩnh",
        "endpointTierCoreExclusiveApi": "Core độc quyền API (radar / thời tiết / gió)",
        "endpointTierCoreStaticExclusive": "Core độc quyền tĩnh",
        "endpointTierLegacyApi": "API kế thừa (api-1)",
    },
    "id": {
        "serverStatusWeb": "Buka halaman status lengkap di browser",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API (EEW / peringatan gempa kuat)",
        "endpointTierLbStatic": "LB statis",
        "endpointTierCoreApi": "Core API (laporan gempa)",
        "endpointTierCoreStatic": "Core statis",
        "endpointTierCoreExclusiveApi": "Core eksklusif API (radar / cuaca / angin)",
        "endpointTierCoreStaticExclusive": "Core eksklusif statis",
        "endpointTierLegacyApi": "API lama (api-1)",
    },
    "fil": {
        "serverStatusWeb": "Buksan ang buong status page sa browser",
        "serverStatusWebUrl": "status.exptech.dev",
        "endpointTierLbApi": "LB API (EEW / malalakas na alerto sa pagyanig)",
        "endpointTierLbStatic": "LB static",
        "endpointTierCoreApi": "Core API (ulat ng lindol)",
        "endpointTierCoreStatic": "Core static",
        "endpointTierCoreExclusiveApi": "Core-eksklusibong API (radar / panahon / hangin)",
        "endpointTierCoreStaticExclusive": "Core-eksklusibong static",
        "endpointTierLegacyApi": "Legacy API (api-1)",
    },
}

ANCHOR = "serverStatusUpdated"


def main() -> None:
    for path in sorted(ARB_DIR.glob("app_*.arb")):
        locale = path.stem.removeprefix("app_")
        if locale not in LOCALES:
            print(f"skip {path.name} (no translations)")
            continue
        updates = LOCALES[locale]
        data = json.loads(path.read_text(encoding="utf-8"))
        if "serverStatusWeb" in data:
            print(f"skip {path.name} (already present)")
            continue
        out = {}
        for key, value in data.items():
            out[key] = value
            if key == ANCHOR:
                out.update(updates)
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()