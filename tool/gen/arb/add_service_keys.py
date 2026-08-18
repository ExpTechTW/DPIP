#!/usr/bin/env python3
"""Insert endpointService* keys after endpointLastSuccessNever in every app_*.arb.

en-US and the zh variants get proper translations; every other locale starts as
the en-US value (placeholder) so l10n generation succeeds, then a translator
pass replaces them.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"

# Order matters: insertion follows this sequence.
SERVICES = [
    "Eew", "Rts", "Radar", "Satellite", "Qpesums", "Wind", "Dpm", "Weather",
    "Rain", "Lightning", "Typhoon", "Report", "TremStation", "Event",
    "Location", "Notify", "Other",
]

EN = {
    "Eew": "EEW",
    "Rts": "RTS",
    "Radar": "Radar",
    "Satellite": "Satellite",
    "Qpesums": "QPE",
    "Wind": "Wind",
    "Dpm": "Disaster points",
    "Weather": "Weather",
    "Rain": "Rain",
    "Lightning": "Lightning",
    "Typhoon": "Typhoon",
    "Report": "EQ reports",
    "TremStation": "Tremor station",
    "Event": "Events",
    "Location": "Location",
    "Notify": "Notifications",
    "Other": "Other",
}

ZH = {
    "Eew": "地震速報",
    "Rts": "強震即時警報",
    "Radar": "雷達",
    "Satellite": "衛星",
    "Qpesums": "定量降水",
    "Wind": "風場",
    "Dpm": "災害點位",
    "Weather": "天氣",
    "Rain": "降雨",
    "Lightning": "閃電",
    "Typhoon": "颱風",
    "Report": "地震報告",
    "TremStation": "震度站",
    "Event": "事件",
    "Location": "定位",
    "Notify": "通知",
    "Other": "其他",
}

# Files written in the zh family (traditional/simplified).
ZH_FILES = {"app_zh.arb", "app_zh_Hans.arb", "app_zh_Hant_HK.arb", "app_zh_TW.arb"}


def main() -> None:
    for path in sorted(ROOT.glob("app_*.arb")):
        data = json.loads(path.read_text(encoding="utf-8"))
        anchor = "endpointLastSuccessNever"
        if anchor not in data:
            print(f"skip {path.name}: missing anchor")
            continue

        values = ZH if path.name in ZH_FILES else EN
        # Re-run protection: if any service key already exists the file is
        # already populated; leave it alone rather than duplicating entries.
        if any(k.startswith("endpointService") for k in data):
            print(f"skip {path.name}: keys already present")
            continue

        entries = []
        for key, value in list(data.items()):
            if key == anchor:
                entries.append((key, value))
                for k in SERVICES:
                    entries.append((f"endpointService{k}", values[k]))
            else:
                entries.append((key, value))

        out = "{\n" + ",\n".join(
            f'  "{k}": {json.dumps(v, ensure_ascii=False)}' for k, v in entries
        ) + "\n}\n"
        path.write_text(out, encoding="utf-8")
        print(f"updated {path.name}")


if __name__ == "__main__":
    main()