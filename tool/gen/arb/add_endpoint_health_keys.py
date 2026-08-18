#!/usr/bin/env python3
"""Rewrite the "本機狀態" copy and add the endpoint-health keys in every ARB.

The local-status block used to be the OS permission checklist; it is now the
client's own reading of the multi-active endpoints (which region actually
answers). Run from repo root: python3 tool/add_endpoint_health_keys.py
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"

# (locale) -> (updated serverStatusLocalBody, new endpoint keys)
LOCALES = {
    "zh": {
        "serverStatusLocalBody": "伺服器指標來自控制台，下方是本機對多活端點（LB / Core 各區）的實際連線判斷：",
        "endpointHealthOk": "本機連線正常",
        "endpointHealthDegraded": "有端點連線不穩",
        "endpointHealthDown": "本機連線異常",
        "endpointHealthUnknown": "尚無觀測資料",
        "endpointHealthNone": "本機尚未對任何端點發出請求。",
        "endpointStateOk": "正常",
        "endpointStateDegraded": "不穩",
        "endpointStateDown": "異常",
        "endpointStateUnknown": "未知",
        "endpointLastSuccessNever": "尚未成功",
    },
    "zh_TW": {
        "serverStatusLocalBody": "伺服器指標來自控制台，下方是本機對多活端點（LB / Core 各區）的實際連線判斷：",
        "endpointHealthOk": "本機連線正常",
        "endpointHealthDegraded": "有端點連線不穩",
        "endpointHealthDown": "本機連線異常",
        "endpointHealthUnknown": "尚無觀測資料",
        "endpointHealthNone": "本機尚未對任何端點發出請求。",
        "endpointStateOk": "正常",
        "endpointStateDegraded": "不穩",
        "endpointStateDown": "異常",
        "endpointStateUnknown": "未知",
        "endpointLastSuccessNever": "尚未成功",
    },
    "zh_Hant_HK": {
        "serverStatusLocalBody": "伺服器指標來自控制台，下方是本機對多活端點（LB / Core 各區）的實際連線判斷：",
        "endpointHealthOk": "本機連線正常",
        "endpointHealthDegraded": "有端點連線不穩",
        "endpointHealthDown": "本機連線異常",
        "endpointHealthUnknown": "尚無觀測資料",
        "endpointHealthNone": "本機尚未對任何端點發出請求。",
        "endpointStateOk": "正常",
        "endpointStateDegraded": "不穩",
        "endpointStateDown": "異常",
        "endpointStateUnknown": "未知",
        "endpointLastSuccessNever": "尚未成功",
    },
    "zh_Hans": {
        "serverStatusLocalBody": "服务器指标来自控制台，下方是本机对多活端点（LB / Core 各区）的实际连接判断：",
        "endpointHealthOk": "本机连接正常",
        "endpointHealthDegraded": "有端点连接不稳",
        "endpointHealthDown": "本机连接异常",
        "endpointHealthUnknown": "暂无观测数据",
        "endpointHealthNone": "本机尚未对任何端点发出请求。",
        "endpointStateOk": "正常",
        "endpointStateDegraded": "不稳",
        "endpointStateDown": "异常",
        "endpointStateUnknown": "未知",
        "endpointLastSuccessNever": "尚未成功",
    },
    "en": {
        "serverStatusLocalBody": "The server metrics above come from the dashboard; below is this device's own view of the multi-active endpoints — which LB / Core region actually answers:",
        "endpointHealthOk": "Local connections healthy",
        "endpointHealthDegraded": "Some endpoints unstable",
        "endpointHealthDown": "Local connections failing",
        "endpointHealthUnknown": "No observations yet",
        "endpointHealthNone": "This device has not yet sent a request to any endpoint.",
        "endpointStateOk": "OK",
        "endpointStateDegraded": "Unstable",
        "endpointStateDown": "Failing",
        "endpointStateUnknown": "Unknown",
        "endpointLastSuccessNever": "never succeeded",
    },
    "ja": {
        "serverStatusLocalBody": "サーバー指標はダッシュボードから取得し、以下はこの端末が実際に接続しているマルチアクティブエンドポイント（LB / Core 各リージョン）の判定です：",
        "endpointHealthOk": "接続正常",
        "endpointHealthDegraded": "不安定なエンドポイントあり",
        "endpointHealthDown": "接続異常",
        "endpointHealthUnknown": "観測データなし",
        "endpointHealthNone": "この端末はまだどのエンドポイントにもリクエストしていません。",
        "endpointStateOk": "正常",
        "endpointStateDegraded": "不安定",
        "endpointStateDown": "異常",
        "endpointStateUnknown": "不明",
        "endpointLastSuccessNever": "未成功",
    },
    "ko": {
        "serverStatusLocalBody": "서버 지표는 대시보드에서 가져오며, 아래는 이 기기가 실제로 연결 중인 멀티 액티브 엔드포인트(LB/Core 각 리전)의 판단입니다:",
        "endpointHealthOk": "연결 정상",
        "endpointHealthDegraded": "불안정한 엔드포인트 있음",
        "endpointHealthDown": "연결 이상",
        "endpointHealthUnknown": "관측 데이터 없음",
        "endpointHealthNone": "이 기기는 아직 어떤 엔드포인트에도 요청하지 않았습니다.",
        "endpointStateOk": "정상",
        "endpointStateDegraded": "불안정",
        "endpointStateDown": "이상",
        "endpointStateUnknown": "알 수 없음",
        "endpointLastSuccessNever": "미성공",
    },
    "th": {
        "serverStatusLocalBody": "ตัวชี้วัดเซิร์ฟเวอร์มาจากแดชบอร์ด ด้านล่างคือการตัดสินของอุปกรณ์นี้ต่อจุดเชื่อมต่อแบบ multi-active (แต่ละภูมิภาคของ LB / Core):",
        "endpointHealthOk": "การเชื่อมต่อปกติ",
        "endpointHealthDegraded": "มีจุดเชื่อมต่อไม่เสถียร",
        "endpointHealthDown": "การเชื่อมต่อผิดปกติ",
        "endpointHealthUnknown": "ยังไม่มีข้อมูล",
        "endpointHealthNone": "อุปกรณ์นี้ยังไม่ได้ส่งคำขอไปยังจุดเชื่อมต่อใด",
        "endpointStateOk": "ปกติ",
        "endpointStateDegraded": "ไม่เสถียร",
        "endpointStateDown": "ผิดปกติ",
        "endpointStateUnknown": "ไม่ทราบ",
        "endpointLastSuccessNever": "ยังไม่สำเร็จ",
    },
    "vi": {
        "serverStatusLocalBody": "Chỉ số máy chủ lấy từ dashboard; bên dưới là nhận định của thiết bị này về các máy chủ multi-active (từng khu vực LB / Core) mà thiết bị thực sự kết nối:",
        "endpointHealthOk": "Kết nối bình thường",
        "endpointHealthDegraded": "Có máy chủ không ổn định",
        "endpointHealthDown": "Kết nối bất thường",
        "endpointHealthUnknown": "Chưa có dữ liệu",
        "endpointHealthNone": "Thiết bị này chưa gửi yêu cầu đến máy chủ nào.",
        "endpointStateOk": "Bình thường",
        "endpointStateDegraded": "Không ổn định",
        "endpointStateDown": "Bất thường",
        "endpointStateUnknown": "Không rõ",
        "endpointLastSuccessNever": "chưa thành công",
    },
    "id": {
        "serverStatusLocalBody": "Metrik server berasal dari dashboard; di bawah ini adalah penilaian perangkat ini terhadap endpoint multi-active (tiap wilayah LB/Core) yang benar-benar terhubung:",
        "endpointHealthOk": "Koneksi normal",
        "endpointHealthDegraded": "Ada endpoint tidak stabil",
        "endpointHealthDown": "Koneksi bermasalah",
        "endpointHealthUnknown": "Belum ada data",
        "endpointHealthNone": "Perangkat ini belum mengirim permintaan ke endpoint mana pun.",
        "endpointStateOk": "Normal",
        "endpointStateDegraded": "Tidak stabil",
        "endpointStateDown": "Bermasalah",
        "endpointStateUnknown": "Tidak diketahui",
        "endpointLastSuccessNever": "belum berhasil",
    },
    "fil": {
        "serverStatusLocalBody": "Ang mga sukatan ng server ay mula sa dashboard; sa ibaba ay ang sariling pagtingin ng device na ito sa mga multi-active endpoint (bawat rehiyon ng LB/Core) na aktwal na kumokonekta:",
        "endpointHealthOk": "Normal ang koneksyon",
        "endpointHealthDegraded": "May endpoint na hindi matatag",
        "endpointHealthDown": "May problema ang koneksyon",
        "endpointHealthUnknown": "Wala pang datos",
        "endpointHealthNone": "Ang device na ito ay hindi pa nagpapadala ng kahit anong request sa endpoint.",
        "endpointStateOk": "Normal",
        "endpointStateDegraded": "Hindi matatag",
        "endpointStateDown": "May problema",
        "endpointStateUnknown": "Hindi alam",
        "endpointLastSuccessNever": "hindi pa nagtagumpay",
    },
}

# Where to insert the new keys so they stay grouped with the server-status ones.
ANCHOR = "serverStatusUpdated"


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
            if key == "serverStatusLocalBody":
                out[key] = updates["serverStatusLocalBody"]
            if key == ANCHOR:
                for k, v in updates.items():
                    if k != "serverStatusLocalBody":
                        out[k] = v
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()