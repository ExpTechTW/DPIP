#!/usr/bin/env bash
# Build both native profiles from the reviewed, merged Rust source tree.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

if [[ $# != 2 || $2 != /* || -e $2 || -L $2 ]]; then
  printf 'Usage: %s <eq-report-pic checkout> <new absolute output directory>\n' "$0" >&2
  exit 2
fi
source tool/internal/report_picture_native.sh
checkout="$(cd "$1" && pwd -P)"
output="$2"
# Run the build driver from the pin, independent of the source checkout's HEAD.
driver="$(mktemp "$checkout/scripts/.dpip-build-story.XXXXXX")"
trap 'rm -f "$driver"' EXIT
git -C "$checkout" show "$eqr_revision:scripts/build-story-qa.sh" > "$driver"
bash "$driver" "$eqr_revision" "$output"
