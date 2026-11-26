#!/usr/bin/env bash
# Run the offline report-picture QA target on one Flutter device ID.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

usage() {
  printf '用法：%s <Flutter device ID> [--smoke | --smoke-4x5 | --smoke-story | --smoke-matrix | --allow-missing-native]\n' "$0" >&2
  exit 2
}

device="${1:-}"
option="${2:-}"
[[ $# -le 2 && -n $device && $device != -* ]] || usage
profile=production
smoke_format=landscape16By9
case "$option" in
  '') target=report_picture_preview ;;
  --smoke) target=report_picture_smoke ;;
  --smoke-4x5) target=report_picture_smoke; smoke_format=information4By5 ;;
  --smoke-story) target=report_picture_smoke; smoke_format=story9By16; profile=qa ;;
  --smoke-matrix) target=report_picture_matrix; profile=qa ;;
  --allow-missing-native) target=report_picture_preview ;;
  *) usage ;;
esac

# Flutter resolves the actual device and architecture, including custom IDs.
devices="$(pinned flutter devices --machine)"
platform="$(python3 -c '
import json, sys
devices = json.load(sys.stdin)
print(next((d["targetPlatform"] for d in devices if d["id"] == sys.argv[1]), ""))
' "$device" <<< "$devices")"

case "$platform" in
  ios) platform=ios ;;
  android-arm64|android-x64) platform=android ;;
  *) printf '找不到支援的裝置 ID：%s\n' "$device" >&2; exit 2 ;;
esac

launcher=(tool/run.sh -d "$device")
if [[ $option != --allow-missing-native ]]; then
  : "${DPIP_EQR_BUILD:?Set DPIP_EQR_BUILD to the output of tool/dev/build_report_picture.sh}"
  launcher=(tool/dev/run_report_sharing.sh "$platform" "$profile" "$device"
    "${DPIP_EQR_CHECKOUT:-../eq-report-pic}" "$DPIP_EQR_BUILD/packages/$profile"
    "$DPIP_EQR_BUILD/trusted/$profile.json")
fi

fixtures=test/features/earthquake/domain/fixtures/share_input
encode() { base64 < "$fixtures/$1" | tr -d '\n'; }

exec "${launcher[@]}" --no-pub --target "tool/qa/$target.dart" \
  --dart-define="DPIP_REPORT_PICTURE_SMOKE_FORMAT=$smoke_format" \
  --dart-define="DPIP_REPORT_PICTURE_CORE_V2=$(encode exptech-modern.json)" \
  --dart-define="DPIP_REPORT_PICTURE_HISTORICAL=$(encode exptech-historical.json)" \
  --dart-define="DPIP_REPORT_PICTURE_FIXTURE=$(encode exptech-modern.v2.json)"
