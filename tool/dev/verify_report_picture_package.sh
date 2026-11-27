#!/usr/bin/env bash
# Verify the renderer in the actual app bundle or APK, using its build stage.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"
source tool/internal/report_picture_native.sh

if [[ $# != 4 || ! $1 =~ ^(ios|android)$ ]]; then
  printf 'Usage: %s {ios|android} <Runner.app or APK> <staged profile directory> <Xcode link map or Android zipalign path>\n' "$0" >&2
  exit 2
fi
digest="$(eqr_manifest_hash "$(basename "$3")")"
exec python3 tool/internal/verify_report_picture_package.py "$@" "$eqr_revision" "$eqr_tree" "$digest"
