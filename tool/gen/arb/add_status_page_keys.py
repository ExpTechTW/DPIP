#!/usr/bin/env python3
"""Insert server-status l10n keys after appLogsNoMatch in every ARB.

Run from repo root: python3 tool/add_status_page_keys.py
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"

NEW_KEYS = {
    "zh": {
        "serverStatusBody": "目前 ExpTech 伺服器的即時健康狀態。",
        "serverStatusLocal": "本機狀態",
        "serverStatusLocalBody": "伺服器正常不代表警報一定到得了，檢查本機權限與背景執行狀態：",
        "serverStatusAllUp": "所有服務正常",
        "serverStatusDegraded": "服務效能下降",
        "serverStatusDown": "服務異常",
        "serverStatusErrorRate": "5xx 錯誤率",
        "serverStatusLatency": "平均延遲",
        "serverStatusUpdated": "更新於",
    },
    "zh_TW": {
        "serverStatusBody": "目前 ExpTech 伺服器的即時健康狀態。",
        "serverStatusLocal": "本機狀態",
        "serverStatusLocalBody": "伺服器正常不代表警報一定到得了，檢查本機權限與背景執行狀態：",
        "serverStatusAllUp": "所有服務正常",
        "serverStatusDegraded": "服務效能下降",
        "serverStatusDown": "服務異常",
        "serverStatusErrorRate": "5xx 錯誤率",
        "serverStatusLatency": "平均延遲",
        "serverStatusUpdated": "更新於",
    },
    "zh_Hant_HK": {
        "serverStatusBody": "目前 ExpTech 伺服器的即時健康狀態。",
        "serverStatusLocal": "本機狀態",
        "serverStatusLocalBody": "伺服器正常不代表警報一定到得了，檢查本機權限與背景執行狀態：",
        "serverStatusAllUp": "所有服務正常",
        "serverStatusDegraded": "服務效能下降",
        "serverStatusDown": "服務異常",
        "serverStatusErrorRate": "5xx 錯誤率",
        "serverStatusLatency": "平均延遲",
        "serverStatusUpdated": "更新於",
    },
    "zh_Hans": {
        "serverStatusBody": "目前 ExpTech 服务器的实时健康状态。",
        "serverStatusLocal": "本机状态",
        "serverStatusLocalBody": "服务器正常不代表警报一定到达，请检查本机权限与后台执行状态：",
        "serverStatusAllUp": "所有服务正常",
        "serverStatusDegraded": "服务性能下降",
        "serverStatusDown": "服务异常",
        "serverStatusErrorRate": "5xx 错误率",
        "serverStatusLatency": "平均延迟",
        "serverStatusUpdated": "更新于",
    },
    "en": {
        "serverStatusBody": "Live health of the ExpTech servers.",
        "serverStatusLocal": "Local status",
        "serverStatusLocalBody": "A healthy server is not enough — alerts also need your device's permissions and background execution:",
        "serverStatusAllUp": "All services operational",
        "serverStatusDegraded": "Services degraded",
        "serverStatusDown": "Service down",
        "serverStatusErrorRate": "5xx error rate",
        "serverStatusLatency": "Avg latency",
        "serverStatusUpdated": "Updated",
    },
    "ja": {
        "serverStatusBody": "ExpTech サーバーのリアルタイムの健全性です。",
        "serverStatusLocal": "デバイスの状態",
        "serverStatusLocalBody": "サーバーが正常でも警報が届くとは限りません。権限とバックグラウンド実行を確認してください：",
        "serverStatusAllUp": "すべて正常",
        "serverStatusDegraded": "パフォーマンス低下",
        "serverStatusDown": "サービス異常",
        "serverStatusErrorRate": "5xx エラー率",
        "serverStatusLatency": "平均遅延",
        "serverStatusUpdated": "更新",
    },
    "ko": {
        "serverStatusBody": "ExpTech 서버의 실시간 상태입니다.",
        "serverStatusLocal": "기기 상태",
        "serverStatusLocalBody": "서버가 정상이어도 알림이 도착하지 않을 수 있습니다. 권한과 백그라운드 실행을 확인하세요:",
        "serverStatusAllUp": "모든 서비스 정상",
        "serverStatusDegraded": "성능 저하",
        "serverStatusDown": "서비스 이상",
        "serverStatusErrorRate": "5xx 오류율",
        "serverStatusLatency": "평균 지연",
        "serverStatusUpdated": "업데이트",
    },
    "th": {
        "serverStatusBody": "สถานะสุขภาพแบบเรียลไทม์ของเซิร์ฟเวอร์ ExpTech",
        "serverStatusLocal": "สถานะอุปกรณ์",
        "serverStatusLocalBody": "เซิร์ฟเวอร์ปกติไม่ได้แปลว่าการแจ้งเตือนจะถึงเสมอ ตรวจสอบสิทธิ์และการทำงานเบื้องหลัง:",
        "serverStatusAllUp": "บริการทั้งหมดปกติ",
        "serverStatusDegraded": "ประสิทธิภาพลดลง",
        "serverStatusDown": "บริการผิดปกติ",
        "serverStatusErrorRate": "อัตราข้อผิดพลาด 5xx",
        "serverStatusLatency": "ความหน่วงเฉลี่ย",
        "serverStatusUpdated": "อัปเดต",
    },
    "vi": {
        "serverStatusBody": "Tình trạng thời gian thực của máy chủ ExpTech.",
        "serverStatusLocal": "Trạng thái thiết bị",
        "serverStatusLocalBody": "Máy chủ bình thường chưa chắc cảnh báo đã đến được. Kiểm tra quyền và chạy nền:",
        "serverStatusAllUp": "Tất cả dịch vụ hoạt động",
        "serverStatusDegraded": "Hiệu suất giảm",
        "serverStatusDown": "Dịch vụ lỗi",
        "serverStatusErrorRate": "Tỷ lệ lỗi 5xx",
        "serverStatusLatency": "Độ trễ trung bình",
        "serverStatusUpdated": "Cập nhật",
    },
    "id": {
        "serverStatusBody": "Status kesehatan server ExpTech secara real-time.",
        "serverStatusLocal": "Status perangkat",
        "serverStatusLocalBody": "Server normal belum tentu notifikasi sampai. Periksa izin dan eksekusi latar:",
        "serverStatusAllUp": "Semua layanan normal",
        "serverStatusDegraded": "Kinerja menurun",
        "serverStatusDown": "Layanan bermasalah",
        "serverStatusErrorRate": "Tingkat error 5xx",
        "serverStatusLatency": "Latensi rata-rata",
        "serverStatusUpdated": "Diperbarui",
    },
    "fil": {
        "serverStatusBody": "Real-time na kalusugan ng mga server ng ExpTech.",
        "serverStatusLocal": "Katayuan ng device",
        "serverStatusLocalBody": "Hindi sapat na normal ang server — kailangan ding gumana ang mga pahintulot at background execution:",
        "serverStatusAllUp": "Lahat ng serbisyo ay normal",
        "serverStatusDegraded": "Bumaba ang pagganap",
        "serverStatusDown": "May problema ang serbisyo",
        "serverStatusErrorRate": "Rate ng error na 5xx",
        "serverStatusLatency": "Karaniwang latency",
        "serverStatusUpdated": "Na-update",
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
        if "serverStatusBody" in data:
            print(f"skip {path.name} (already present)")
            continue
        out = {}
        for key, value in data.items():
            out[key] = value
            if key == "appLogsNoMatch":
                out.update(insert)
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()