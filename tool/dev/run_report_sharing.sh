#!/usr/bin/env bash
# Stage a freshly verified renderer and start the normal report detail flow.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"
source tool/internal/report_picture_native.sh

platform="${1:-}"
profile="${2:-}"
if [[ $# -lt 6 || ! $platform =~ ^(ios|android)$ || ! $profile =~ ^(production|qa)$ ]]; then
  printf 'Usage: %s {ios|android} {production|qa} <device ID> <Rust checkout> <package> <independent trusted manifest> [run arguments]\n' "$0" >&2
  exit 2
fi
device="$3"
for argument in "${@:7}"; do
  case "$argument" in
    --flavor|--flavor=*|-d|--device-id|--device-id=*)
      printf 'The launcher selects the device and flavor.\n' >&2
      exit 2 ;;
    --profile|--release)
      if [[ $profile == qa ]]; then
        printf 'Story QA is a debug-only configuration.\n' >&2
        exit 2
      fi ;;
  esac
done
mkdir -p native/eq_report_pic/staging
stage="$(mktemp -d "$(pwd -P)/native/eq_report_pic/staging/$platform-$profile.XXXXXX")"
eqr_stage "$(cd "$4" && pwd -P)" "$profile" "$5" "$6" "$stage"
package="$stage/$profile"
eqr_stage_fonts "$package"
shift 6

flavor=production
story_qa=false
if [[ $profile == qa ]]; then
  flavor=storyqa
  story_qa=true
fi
if [[ $platform == ios ]]; then
  # Xcode reads this per-invocation file. The project selects the only matching
  # profile, independently of the Flutter flavor passed below.
  export XCODE_XCCONFIG_FILE="$stage/link.xcconfig"
  prefix="DPIP_EQR_$(tr '[:lower:]' '[:upper:]' <<< "$profile")"
  framework=EqReportPic
  stem=libeq_report_pic
  if [[ $profile == qa ]]; then
    framework=EqReportPicStoryQA
    stem=libeq_report_pic_story_qa
  fi
  {
    printf '%s_ROOT = %s\n' "$prefix" "$package"
    # xcconfig treats // as a comment, including when it occurs in a literal.
    printf '%s_LINK = -Wl,-force_load,"$(%s_ROOT)/ios/%s.xcframework/$(DPIP_EQR_SLICE)/%s.a" -Wl,-export_dynamic' \
      "$prefix" "$prefix" "$framework" "$stem"
    python3 - "$package/manifest.json" <<'PYLINK'
import json
import sys
with open(sys.argv[1]) as manifest:
    for symbol in json.load(manifest)["symbols"]:
        print(f" -Wl,-u,_{symbol}", end="")
print()
PYLINK
  } > "$XCODE_XCCONFIG_FILE"
else
  export DPIP_EQR_STAGE="$package"
fi

printf 'Report renderer staging: %s\n' "$stage" >&2
exec tool/run.sh --flavor "$flavor" -d "$device" "$@" \
  --dart-define="DPIP_EQR_STORY_QA=$story_qa" \
  --dart-define="DPIP_EQR_REVISION=$eqr_revision" \
  --dart-define="DPIP_EQR_MANIFEST_SHA256=$(eqr_manifest_hash "$profile")"
