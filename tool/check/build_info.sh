#!/usr/bin/env bash
# The committed build_info.g.dart is a stub, and the generator writes the real
# one. They must declare the same names: a symbol added to the generator but not
# to the stub compiles on the author's machine — the file is `skip-worktree`, so
# their copy has it — and fails on any fresh checkout.
set -euo pipefail
cd "$(dirname "$0")/../.."
names() { grep -oE '^const [A-Za-z<>]+ (k[A-Za-z]+)' "$1" | awk '{print $3}' | sort; }
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
git show HEAD:lib/core/build_info.g.dart > "$tmp" 2>/dev/null || cp lib/core/build_info.g.dart "$tmp"
bash tool/release/build_info.sh
if ! diff -q <(names "$tmp") <(names lib/core/build_info.g.dart) >/dev/null; then
  echo "::error::the committed build_info.g.dart stub and tool/release/build_info.sh declare different symbols"
  diff <(names "$tmp") <(names lib/core/build_info.g.dart) || true
  exit 1
fi
echo "build info: stub and generator agree"
