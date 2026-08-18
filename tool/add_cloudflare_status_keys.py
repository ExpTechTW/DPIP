#!/usr/bin/env python3
"""Insert the Cloudflare-status l10n keys after serverStatusWebUrl in every ARB.

Run from repo root: python3 tool/add_cloudflare_status_keys.py, then gen-l10n.
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"

NEW_KEYS = {
    "zh": {
        "serverStatusExpTech": "ExpTech 状态",
        "serverStatusCloudflare": "Cloudflare 状态",
        "serverStatusCloudflareAllOperational": "所有区域正常",
        "serverStatusCloudflareOutage": "Cloudflare 部分区域异常",
        "serverStatusCloudflareNone": "目前没有可显示的区域。",
        "serverStatusCloudflareOperational": "正常",
        "serverStatusCloudflareDegraded": "性能下降",
        "serverStatusCloudflarePartial": "部分中断",
        "serverStatusCloudflareMajor": "大规模中断",
        "serverStatusCloudflareUnknown": "未知",
    },
    "zh_TW": {
        "serverStatusExpTech": "ExpTech 狀態",
        "serverStatusCloudflare": "Cloudflare 狀態",
        "serverStatusCloudflareAllOperational": "所有區域正常",
        "serverStatusCloudflareOutage": "Cloudflare 部分區域異常",
        "serverStatusCloudflareNone": "目前沒有可顯示的區域。",
        "serverStatusCloudflareOperational": "正常",
        "serverStatusCloudflareDegraded": "效能下降",
        "serverStatusCloudflarePartial": "部分中斷",
        "serverStatusCloudflareMajor": "大規模中斷",
        "serverStatusCloudflareUnknown": "未知",
    },
    "zh_Hant_HK": {
        "serverStatusExpTech": "ExpTech 狀態",
        "serverStatusCloudflare": "Cloudflare 狀態",
        "serverStatusCloudflareAllOperational": "所有區域正常",
        "serverStatusCloudflareOutage": "Cloudflare 部分區域異常",
        "serverStatusCloudflareNone": "目前沒有可顯示的區域。",
        "serverStatusCloudflareOperational": "正常",
        "serverStatusCloudflareDegraded": "效能下降",
        "serverStatusCloudflarePartial": "部分中斷",
        "serverStatusCloudflareMajor": "大規模中斷",
        "serverStatusCloudflareUnknown": "未知",
    },
    "zh_Hans": {
        "serverStatusExpTech": "ExpTech 状态",
        "serverStatusCloudflare": "Cloudflare 状态",
        "serverStatusCloudflareAllOperational": "所有区域正常",
        "serverStatusCloudflareOutage": "Cloudflare 部分区域异常",
        "serverStatusCloudflareNone": "目前没有可显示的区域。",
        "serverStatusCloudflareOperational": "正常",
        "serverStatusCloudflareDegraded": "性能下降",
        "serverStatusCloudflarePartial": "部分中断",
        "serverStatusCloudflareMajor": "大规模中断",
        "serverStatusCloudflareUnknown": "未知",
    },
    "en": {
        "serverStatusExpTech": "ExpTech status",
        "serverStatusCloudflare": "Cloudflare status",
        "serverStatusCloudflareAllOperational": "All regions operational",
        "serverStatusCloudflareOutage": "Cloudflare regional issue",
        "serverStatusCloudflareNone": "No regions to show.",
        "serverStatusCloudflareOperational": "Operational",
        "serverStatusCloudflareDegraded": "Degraded",
        "serverStatusCloudflarePartial": "Partial outage",
        "serverStatusCloudflareMajor": "Major outage",
        "serverStatusCloudflareUnknown": "Unknown",
    },
    "ja": {
        "serverStatusExpTech": "ExpTech ステータス",
        "serverStatusCloudflare": "Cloudflare ステータス",
        "serverStatusCloudflareAllOperational": "全リージョン正常",
        "serverStatusCloudflareOutage": "Cloudflare の一部リージョンで異常",
        "serverStatusCloudflareNone": "表示できるリージョンがありません。",
        "serverStatusCloudflareOperational": "正常",
        "serverStatusCloudflareDegraded": "性能低下",
        "serverStatusCloudflarePartial": "部分停止",
        "serverStatusCloudflareMajor": "大規模停止",
        "serverStatusCloudflareUnknown": "不明",
    },
    "ko": {
        "serverStatusExpTech": "ExpTech 상태",
        "serverStatusCloudflare": "Cloudflare 상태",
        "serverStatusCloudflareAllOperational": "모든 리전 정상",
        "serverStatusCloudflareOutage": "Cloudflare 일부 리전 이상",
        "serverStatusCloudflareNone": "표시할 리전이 없습니다.",
        "serverStatusCloudflareOperational": "정상",
        "serverStatusCloudflareDegraded": "성능 저하",
        "serverStatusCloudflarePartial": "부분 중단",
        "serverStatusCloudflareMajor": "대규모 중단",
        "serverStatusCloudflareUnknown": "알 수 없음",
    },
    "th": {
        "serverStatusExpTech": "สถานะ ExpTech",
        "serverStatusCloudflare": "สถานะ Cloudflare",
        "serverStatusCloudflareAllOperational": "ทุกภูมิภาคปกติ",
        "serverStatusCloudflareOutage": "Cloudflare บางภูมิภาคผิดปกติ",
        "serverStatusCloudflareNone": "ไม่มีภูมิภาคให้แสดง",
        "serverStatusCloudflareOperational": "ปกติ",
        "serverStatusCloudflareDegraded": "ประสิทธิภาพลดลง",
        "serverStatusCloudflarePartial": "หยุดบางส่วน",
        "serverStatusCloudflareMajor": "หยุดบริการขนาดใหญ่",
        "serverStatusCloudflareUnknown": "ไม่ทราบ",
    },
    "vi": {
        "serverStatusExpTech": "Trạng thái ExpTech",
        "serverStatusCloudflare": "Trạng thái Cloudflare",
        "serverStatusCloudflareAllOperational": "Tất cả khu vực hoạt động",
        "serverStatusCloudflareOutage": "Cloudflare có khu vực bất thường",
        "serverStatusCloudflareNone": "Không có khu vực nào để hiển thị.",
        "serverStatusCloudflareOperational": "Hoạt động",
        "serverStatusCloudflareDegraded": "Hiệu suất giảm",
        "serverStatusCloudflarePartial": "Gián đoạn một phần",
        "serverStatusCloudflareMajor": "Gián đoạn lớn",
        "serverStatusCloudflareUnknown": "Không rõ",
    },
    "id": {
        "serverStatusExpTech": "Status ExpTech",
        "serverStatusCloudflare": "Status Cloudflare",
        "serverStatusCloudflareAllOperational": "Semua wilayah normal",
        "serverStatusCloudflareOutage": "Cloudflare beberapa wilayah bermasalah",
        "serverStatusCloudflareNone": "Tidak ada wilayah untuk ditampilkan.",
        "serverStatusCloudflareOperational": "Normal",
        "serverStatusCloudflareDegraded": "Kinerja menurun",
        "serverStatusCloudflarePartial": "Gangguan sebagian",
        "serverStatusCloudflareMajor": "Gangguan besar",
        "serverStatusCloudflareUnknown": "Tidak diketahui",
    },
    "fil": {
        "serverStatusExpTech": "Katayuan ng ExpTech",
        "serverStatusCloudflare": "Katayuan ng Cloudflare",
        "serverStatusCloudflareAllOperational": "Normal ang lahat ng lugar",
        "serverStatusCloudflareOutage": "May problema ang Cloudflare sa ilang lugar",
        "serverStatusCloudflareNone": "Walang lugar na maipapakita.",
        "serverStatusCloudflareOperational": "Normal",
        "serverStatusCloudflareDegraded": "Bumaba ang pagganap",
        "serverStatusCloudflarePartial": "Bahagyang pagkaantala",
        "serverStatusCloudflareMajor": "Malaking pagkaantala",
        "serverStatusCloudflareUnknown": "Hindi alam",
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
        if "serverStatusCloudflare" in data:
            print(f"skip {path.name} (already present)")
            continue
        out = {}
        for key, value in data.items():
            out[key] = value
            if key == "serverStatusWebUrl":
                out.update(insert)
        if "serverStatusCloudflare" not in out:
            out.update(insert)
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()