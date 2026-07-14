#!/usr/bin/env bash
#
# One-time developer setup. Run after cloning:  bash tool/setup.sh
#
# Installs the repo's git hooks (.githooks) and generates the build-info file so
# the Debug-info page shows the current commit. `skip-worktree` keeps the local
# per-commit churn of build_info.g.dart out of `git status` (the committed value
# is a harmless default; each dev's hooks keep their own copy current). To edit
# the committed file intentionally later:
#   git update-index --no-skip-worktree lib/core/build_info.g.dart
set -euo pipefail
cd "$(dirname "$0")/.."

git config core.hooksPath .githooks
bash tool/gen_build_info.sh
git update-index --skip-worktree lib/core/build_info.g.dart 2>/dev/null || true

echo "Setup done: git hooks → .githooks; build_info.g.dart generated + skip-worktree."
