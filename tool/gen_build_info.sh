#!/usr/bin/env bash
#
# Writes lib/core/build_info.g.dart with what git knows about this build: the
# short commit hash, and the label and ordinal tool/version.sh derives.
#
# CI passes the label and ordinal in with --dart-define, but a local
# `flutter run` never goes through CI — so a debug build fell back to the
# pubspec placeholder and reported itself as `26.1.0 (1)`, which is not a
# version that exists anywhere. A generated source file is the only way to get
# git state into a debug build: it is compiled in at `flutter run`, survives
# hot reload, and needs no flag to be remembered.
#
# Run by the git hooks in .githooks/ (installed once via tool/setup.sh) on
# commit / checkout / merge, so it tracks HEAD by itself. Idempotent: only
# rewrites when a value changes, so it never dirties the tree for nothing.
set -euo pipefail
cd "$(dirname "$0")/.."

out="lib/core/build_info.g.dart"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

# Best-effort. Outside a repo, or in a shallow clone that cannot count commits,
# these stay empty and the app falls back to the platform's own version rather
# than printing something that is not true.
label=""
code="0"
last_release=""
if version="$(tool/version.sh 2>/dev/null)"; then
  eval "$version"
  label="${DPIP_LABEL:-}"
  code="${DPIP_CODE:-0}"
  last_release="${DPIP_LAST_RELEASE:-}"
fi

new="$(cat <<EOF
// GENERATED — do not edit by hand. Written by tool/gen_build_info.sh (run by the
// git hooks in .githooks/; set up once with tool/setup.sh). Holds what git knows
// about this build, so a debug build can name itself without CI's --dart-define.
library;

/// Short git commit hash of HEAD at generation time ('unknown' outside a repo).
const String kGitCommit = '$commit';

/// The label tool/version.sh derives for HEAD — '26w33b', '26.1'. Empty when
/// git could not answer, in which case the platform's own version is used.
const String kBuildLabel = '$label';

/// The ordinal that goes with it; 0 when git could not answer.
const int kBuildCode = $code;

/// The newest release tag this history knows, 'v' stripped — '26.1'. Empty
/// before the first release, in which case the version card shows the label.
const String kLastRelease = '$last_release';
EOF
)"

if [ ! -f "$out" ] || [ "$(cat "$out")" != "$new" ]; then
  printf '%s\n' "$new" > "$out"
fi
