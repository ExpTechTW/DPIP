#!/usr/bin/env bash
# One-time developer setup, after cloning:
#
#     tool/dev/setup.sh
#
# Installs the repo's git hooks (.githooks) and generates the build-info file so
# the Debug-info page shows the current commit. `skip-worktree` keeps the local
# per-commit churn of build_info.g.dart out of `git status` (the committed value
# is a harmless default; each dev's hooks keep their own copy current). To edit
# the committed file intentionally later:
#   git update-index --no-skip-worktree lib/core/build_info.g.dart
#
# `tool/run.sh` runs this itself when the hooks are not installed, so a fresh
# clone that goes straight to running the app still gets them. Running it by
# hand is for everything else — a clone you intend to build but not run.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

git config core.hooksPath .githooks
bash tool/release/build_info.sh
git update-index --skip-worktree lib/core/build_info.g.dart 2>/dev/null || true

echo "Setup done: git hooks → .githooks; build_info.g.dart generated + skip-worktree."
