#!/usr/bin/env bash
# Run the offline report-picture QA target on one Flutter device ID.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

usage() {
  printf '用法：%s <Flutter device ID> [--smoke | --allow-missing-native]\n' "$0" >&2
  exit 2
}

device="${1:-}"
option="${2:-}"
[[ $# -le 2 && -n $device && $device != -* ]] || usage
case "$option" in
  '') target=report_picture_preview ;;
  --smoke) target=report_picture_smoke ;;
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

runtime=native/eq_report_pic
case "$platform" in
  ios)
    platform=ios
    artifacts=("$runtime/ios/link.xcconfig"
      "$runtime/ios/EqReportPic.xcframework/ios-arm64_x86_64-simulator/libeq_report_pic.a"
      "$runtime/ios/EqReportPic.xcframework/ios-arm64/libeq_report_pic.a")
    ;;
  android-arm64)
    platform=android
    artifacts=("$runtime/android/arm64-v8a/libeq_report_pic.so")
    ;;
  android-x64)
    platform=android
    artifacts=("$runtime/android/x86_64/libeq_report_pic.so")
    ;;
  *)
    printf '找不到支援的裝置 ID：%s。請先啟動 iOS 或 Android 模擬器。\n' "$device" >&2
    exit 2
    ;;
esac

if [[ $option != --allow-missing-native ]]; then
  for artifact in "${artifacts[@]}" assets/fonts/report/{mplus-2p-bold,GenShinGothic-Bold,NotoSansTC-Black}.ttf; do
    if [[ ! -s $artifact ]]; then
      printf '缺少原生產物：%s\n請用本機 eq-report-pic checkout 執行：\n  tool/dev/build_report_picture.sh %s ../eq-report-pic\n' "$artifact" "$platform" >&2
      exit 1
    fi
  done
fi

fixtures=test/features/earthquake/domain/fixtures/share_input
encode() { base64 < "$fixtures/$1" | tr -d '\n'; }

exec tool/run.sh -d "$device" --no-pub --target "tool/qa/$target.dart" \
  --dart-define="DPIP_REPORT_PICTURE_CORE_V2=$(encode exptech-modern.json)" \
  --dart-define="DPIP_REPORT_PICTURE_HISTORICAL=$(encode exptech-historical.json)" \
  --dart-define="DPIP_REPORT_PICTURE_FIXTURE=$(encode exptech-modern.v2.json)"
