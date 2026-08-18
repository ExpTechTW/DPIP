#!/usr/bin/env bash
# Fail if pubspec.lock embeds a machine-local path dependency.
#
# `pubspec_overrides.yaml` is gitignored for local maplibre fork work, but
# `flutter pub get` with it active rewrites maplibre_gl in pubspec.lock to
# `source: path` + an absolute /Users/... path. Committing that makes CI's
# `pub get` rewrite the lock back to git → dirty tree → false "codegen stale".
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
lock="$root/pubspec.lock"

if [[ ! -f "$lock" ]]; then
  echo "pubspec.lock missing" >&2
  exit 1
fi

# Absolute POSIX / Windows paths in the lock description.
if grep -E '^\s+path: ["'\'']?(/|[A-Za-z]:\\)' "$lock" >/dev/null; then
  echo "Prefs-style lock gate failed: pubspec.lock has an absolute path dependency." >&2
  echo "Usually caused by committing after \`flutter pub get\` with pubspec_overrides.yaml." >&2
  echo "Fix: move overrides aside → flutter pub get → commit pubspec.lock → restore overrides." >&2
  grep -nE '^\s+path: ["'\'']?(/|[A-Za-z]:\\)' "$lock" >&2 || true
  exit 1
fi

echo "pubspec.lock OK — no absolute path dependencies."
