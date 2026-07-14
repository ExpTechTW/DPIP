#!/usr/bin/env bash
#
# Writes lib/core/build_info.g.dart with the current HEAD's short commit hash, so
# the Debug-info page can show which commit a build came from. Run by the git
# hooks in .githooks/ (installed via tool/setup.sh) on commit / checkout / merge,
# so the file tracks HEAD automatically — no --dart-define, works in debug + hot
# reload (it's a plain source file, compiled in at `flutter run`). Idempotent:
# only rewrites when the value changes.
set -euo pipefail
cd "$(dirname "$0")/.."

out="lib/core/build_info.g.dart"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

new="$(cat <<EOF
// GENERATED — do not edit by hand. Written by tool/gen_build_info.sh (run by the
// git hooks in .githooks/; set up once with tool/setup.sh). Holds the commit the
// build was made from, shown on the Debug-info page.
library;

/// Short git commit hash of HEAD at generation time ('unknown' outside a repo).
const String kGitCommit = '$commit';
EOF
)"

if [ ! -f "$out" ] || [ "$(cat "$out")" != "$new" ]; then
  printf '%s\n' "$new" > "$out"
fi
